try {
  WokerPool ==undefined;
}
catch(e){
//Register for onload evnets from chunks
//Find all chunks
//
//
function bootstrap(parameters){
	//Also will have options passsed here
//	setInterval(()=>{console.log("From template worker", JSON.parse(parameters))},1000);
	let scope=self;
	self["addFunction"]=function (argHash){
		self[argHash.name]= new Function(argHash.arg,argHash.body);
		//console.log("addFunction from worker",self[argHash.name]);
		return ["addFunctionReturn",{},[]];
	}

	self["importScript"]=function(argHash){
		eval(argHash);	
		return["importScriptReturn",{},[]];
	}

	function decode(options,  string){
		//console.log("DECODE IN BOOTSTRAP",options,string);
		//Convert from string to arraybuffer	
		let binaryData=atob(string);
		let len=binaryData.length;
		let array=new Uint8Array(len);	//number of characters
		for(let i=0;i<len;i++){
			array[i]=binaryData.charCodeAt(i);
		}

		//Now decompress if we need to
		let out;
		switch(options.jpack_compression){
			case 'DEFLATE':
			case 'deflate':

				try {
					out=pako.inflate(array,{raw:true});
				}
				catch (e){

					console.log("Problem inflating data");
					console.log(e);
				}
				break;
			case 'NONE':
			case 'none':
				out=array;
				break;
			default:
				//TODO: throw exception
				out=array;
				break;
		}
		return out;
	}
	self["decode"]=function(argHash){
		let out=decode(argHash.options,argHash.string);
		return ["decodeReturn",out,[]];
	}


	
        onmessage=function(e){

				//console.log("remote function call",e.data);
				let name,result,transfer;
				[name,result,transfer]=scope[e.data.name](e.data.arg);
				postMessage({cmd:"callFunctionReturn",name:name,result:result},transfer);
	}
}



//Stub class providing functional access to worker
class WorkerTemplate{
	constructor(parameters){
		this.id=parameters.id;
		let p=JSON.stringify(parameters);

		let code="("+bootstrap.toString();
		code+=")(\'"+p+"\')";
		//console.log(code);
		//this.promise=undefined;
		let blob=new Blob([code],{type:"text/javascript"});
		this.worker=new Worker(window.URL.createObjectURL(blob));
		this.worker.addEventListener("message",(e)=>this.fromWorker(e));

		//Setup a queue for requests
		this.isBusy=false;
		this.requestQueue=[];
		this.responseQueue=[];//this should only every have 0 or 1 elements
	}

	fromWorker(e){

		switch(e.data.cmd){
			case "callFunctionReturn":
				let r=this.responseQueue.shift();
				//console.log(`Response from worker ${this.id}`);
				r.resolver(e);
				this.isBusy=false;
				this._executeNext();	//Trigger the queue again
				//Resolve the promise with the e
				//this.manager.returnCall(this, e);
				break;
			default:
				break;
		}

		this.worker
	}



	callFunction(name, arg, transfer){
		//Add to the queue
		let resolver;
    let rejecter;
		let promise=new Promise((resolve, reject)=>{
			resolver=resolve;
      rejecter=reject;
		});
		this.requestQueue.push({name,arg,transfer,resolver,rejecter});
		this._executeNext();
		return promise;

	}
	_executeNext(){
    //console.log("is busy", this.isBusy);
		if((!this.isBusy) && (this.requestQueue.length>0)){
			//console.log(`POSTING TO WORKER ${this.id}`);
			this.isBusy=true;
			let r=this.requestQueue.shift();
			this.responseQueue.push(r);
      //console.log("_in execute next", r);
      try {
			  this.worker.postMessage({cmd:"callFunction",name:r.name, arg:r.arg },r.transfer);
      }
      catch(e){
        let er={data:{name:"error", result:undefined}};
        // Could not send message, probably a bad argument. Make as not busy
				let r=this.responseQueue.shift();
				//console.log(`Response from worker ${this.id}`);
				r.rejecter(er);
				this.isBusy=false;
				this._executeNext();	//Trigger the queue again
      }

		}
	}
}


class WorkerPool {
	constructor(count){
		this.availableQueue=[];
		this.pool=[];
		this.callQueue=[];
		this.callMap={};
		this.addWorkers(count);
		this.callID=0;
		this.existingFunctions=[];
	}

	addWorkers(count){
		//Generate pool of workers
		let w;
		let id=this.pool.length;
		for(let i=0;i<count;i++){
			w=new WorkerTemplate({id:id+i});
			this.pool.push(w);
			this.availableQueue.push(w);
			w.manager=this;
		}
	}

	addScriptBody(string){
    //console.log("Add script body");
    //console.log(string);
		let p=[];
		for(let i=0;i<this.pool.length;i++){
			p.push(this.pool[i].callFunction("importScript",string,[]));
		}
		return Promise.all(p);
		
	}
	addFunctions(refs,names){
    //console.log("Add functions");
    //console.log(refs);
		let p=[];
		if(names===undefined){
			names=new Array(refs.length);
		}
		//console.log(refs,names);
		for(let i=0;i<refs.length;i++){
			p.push(this.addFunction(refs[i],names[i]));
		}
		return Promise.all(p);
	}
	//Directly calls each worker to add the function.
	addFunction(ref,name,apiFlag){
    //console.log("Add function");
    //console.log(ref);
		//Testif function alread has been added to the pool
		for(let i=0;i<this.existingFunctions.length;i++){
			if(this.existingFunctions[i]==ref){
				console.log("Existing function.. not adding", ref.name);
				return Promise.resolve();
			}
		}
		//console.log("POOL adding new function",ref.name);
		this.existingFunctions.push(ref);
		let string=ref.toString();
		let n=string.substring(string.indexOf(" ")+1,string.indexOf("("));
		if(n==""){
			n=name;
		}
		let arg=string.substring(string.indexOf("(")+1,string.indexOf(")")).split(",");
		let body=string.substring(string.indexOf("\{")+1,string.length-1);
		let p=[];
		for(let i=0;i<this.pool.length;i++){
			p.push(this.pool[i].callFunction("addFunction",{name:n,apiFlag:apiFlag,arg:arg,body:body}));
		}
		return Promise.all(p);
	}

	//Add a function call to the queue. Start execution if possible
	//Multiple calls to this will queue calls and will grow unbounded.
	//Also multiple calls using the same transferable objects wont work
	//To ensure sane sequencing, use callFunction instead
	
	//Round robin worker selection
	queueFunction(name, arg, transfer){
		let wid=this.callID%this.pool.length;
		this.callID++;
		return this.pool[wid].callFunction(name,arg,transfer)
		.then((e)=>{
			return Promise.resolve({name:e.data.name, result:e.data.result});

		});

	}

}

//Work around/helper for loading workers from local files. also works with served files
class ScriptLoader {
	constructor(selfSrc){
    this.src=selfSrc;
		this.pool=new WorkerPool(4);
		this.promises={};
		this.scripts={};		//Map of urls which already are loaded/seen before

    console.log("SELF SOURCE "+ this.src);
	}
	setStatusDisplay(statusDisplay){

		this.statusDisplay=statusDisplay;
	}

	updateStatus(message,mode){
		if(mode==undefined){
			mode="transient";
		}
		let e=new CustomEvent("chunkloading", {bubbles:true,detail:{message:message,mode:mode}});
		if(this.statusDisplay!=undefined){
			document.body.dispatchEvent(e)
		}
	}

	/**
	 * Add a script to the head of the document. Script is defered/async
	 * Returns a promise, which is resolved when the script has loaded/parsed.
	 * This has no throttling so many scripts can be downloaded at once
	 */
	loadScript(scriptURL, id){
		if(this.promises[scriptURL]==undefined){
			let script=document.createElement("script");
			script.src=scriptURL;
			script.type="text/javascript";		//has to be text/javascript for onload events
			script.id=id||scriptURL;
			script.async=true;
			script.defer=true;
			let scope=this;
			this.promises[scriptURL]=new Promise((resolve,reject)=>{
				//console.log("in Promise setup");
				script.onload=(e)=>{
					//console.log("SCRIPT LOADED",e);
					scope.scripts[scriptURL]=e.target;
					//console.log("SCOPE", scope);
					resolve(scope.scripts[scriptURL]);
					//Reset promise
					scope.promises[scriptURL]=undefined;
				};
				script.onerror=(e)=>{
					//console.log(e, "ERROR LOAZDING scirpt");
					scope.scripts[scriptURL]=e.target;
					reject("asdf");
				};

			});
			document.head.appendChild(script);
		}
		return this.promises[scriptURL];	//return the promise
	}


	unloadScript(scriptURL){
    //console.log("unloading script "+scriptURL);
    //console.log(this.scripts);
		if(this.scripts[scriptURL]){
      //console.log("UNLOADING SCRIPT===============", scriptURL);
      //console.log(this.scripts[scriptURL]);
      if(this.scripts[scriptURL].parentElement){
			  this.scripts[scriptURL].parentElement.removeChild(this.scripts[scriptURL]);
      }
			this.promises[scriptURL]=undefined;
		}
	}
}



// A progress indicator. Show progress when under 100%. Show stripes when over 100%
class LoadingDisplay {
	constructor(targetDiv){
		this.target=targetDiv;
		this.autoHide=0;	

		this.dc=document.createElement("div");
		this.dc.id="chunkloadingdiv";

    this.d=document.createElement("div");
    this.d.classList.add("progress");
    this.bar=document.createElement("div");
    this.bar.classList.add("progress-bar");
    this.bar.setAttribute("role","progressbar");
    this.label=document.createElement("div");
    
    this.d.appendChild(this.bar);

    this._setProgress(0);
    this._setLabel("Init");

    this.dc.appendChild(this.d);
    this.dc.appendChild(this.label);

    this.target.appendChild(this.dc);

    let scope=this;
    window.addEventListener("JPACK_STATUS",(e)=>{
      //console.log(e.detail);
      scope._setProgress(e.detail.progress); 
      scope._setLabel(e.detail.message);
      if(e.detail.mode){
        //This is close
        this.dc.style.display="none";
      }
      else {
        this.dc.style.display="block";
      }

    });
	}
  
  _setLabel(label){
    this.label.innerHTML="<br>"+label;
  }

  _setProgress(progress){
    let b=this.bar;

    // Clamp the progress 
    let clamp=progress;
    if(progress>100){
      clamp=100;
      b.classList.add("progress-bar-striped", "progress-bar-animated");
    }
    if(progress<0){
      clamp=0;
      b.classList.add("progress-bar-striped", "progress-bar-animated");
    }
    else {
      b.classList.remove("progress-bar-striped", "progress-bar-animated");
    }

    // Set the progress
    b.setAttribute("style", `width: ${clamp}%`);
    b.setAttribute("aria-valuenow",clamp);
    b.innerHTML=`${clamp}%`;
  }
}

// Create gloabl scriptLoader variable
scriptLoader=new ScriptLoader();

window.LoadingDisplay=LoadingDisplay;
window.WorkerPool=WorkerPool
window.ScriptLoader=ScriptLoader;
window.WorkerTemplate=WorkerTemplate;

}
