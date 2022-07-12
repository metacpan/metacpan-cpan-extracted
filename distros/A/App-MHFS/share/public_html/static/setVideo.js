var theParent = document.getElementById('medialist');
theParent.addEventListener("click", SetVideo, false);

function SetVideo(e){
	if(e.target === e.currentTarget) {
            return;
	}

	if(e.target.getAttribute('class') !== 'mediafile') {
		return;
	}

	console.log('SetVideo - target: ' + e.target);
	let targeturl = e.target.getAttribute('href');
	if(targeturl === null) {
		return;
	}
	targeturl = targeturl.replace('video', 'get_video')
	console.log('SetVideo - url: ' + targeturl)
    e.stopPropagation();
    e.preventDefault();

    _SetVideo(targeturl);
    window.location.hash = '#video';
}

// set the video if provided
let pageurl = new URL(window.location);
const videoname = pageurl.searchParams.get('name');
if(videoname) {
	const fmt = pageurl.searchParams.get('fmt') || 'noconv';
	if(fmt !== 'jsmpeg') {
		_SetVideo('get_video?name='+videoname+'&fmt='+fmt);
		window.location.hash = '#video';
	}
}
