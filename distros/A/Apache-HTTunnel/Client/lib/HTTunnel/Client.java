package HTTunnel ;
import java.util.* ;
import java.io.* ;
import java.net.* ;


public class Client {
	private URL url = null ;
	private String fhid = null ;
	private String proto = null ;
	private String peer_info = null ;


	public Client(String _url) throws MalformedURLException {
		url = new URL(_url) ;
	}


	public int connect(String proto, String host, int port) throws ClientException {
		return connect(proto, host, port, 0) ;
	}

	public int connect(String _proto, String host, int port, int timeout) throws ClientException {
		proto = _proto ;
		if ((proto == null)||(proto.equals(""))){
			proto = "tcp" ;
		}
		if ((host == null)||(host.equals(""))){
			host = "localhost" ;
		}
		if (timeout <= 0){
			timeout = 15 ;
		}

		fhid = execute("connect", 
			new String [] { proto, host, 
				(new Integer(port)).toString(), (new Integer(timeout)).toString() }
		) ;
		if (proto.equals("tcp")){
			StringTokenizer st = new StringTokenizer(fhid, ":", true) ;
			addr = st.nextToken() ; 
			st.nextToken() ; // waste ':'
			port = st.nextToken() ; 
			st.nextToken() ; // waste ':'
			StringBuffer sbfhid = new StringBuffer() ;
			while (st.hasMoreTokens()){
				sbfhid.append(st.nextToken()) ;
			}
			fhid = sbfhid.toString() ;
			peer_info = addr + ":" + port ;
		}

		return 1 ;
	}


	public String read(int len) throws ClientException {
		return read(len, 0) ;
	}

	public String read(int len, int timeout) throws ClientException {
		if (timeout <= 0){
			timeout = 15 ;
		}

		if (fhid == null){
			throw new ClientException("HTTunnel.Client object is not connected") ;
		}

		while (true){
			String addr = null ;
			String port = null ;
			String data = null ;
			try {
				data = execute(
					"read", 
					new String [] { fhid, proto, (new Integer(len)).toString(),
						(new Integer(timeout)).toString() }
				) ;
				if (proto.equals("udp")){
					StringTokenizer st = new StringTokenizer(data, ":", true) ;
					addr = st.nextToken() ; 
					st.nextToken() ; // waste ':'
					port = st.nextToken() ; 
					st.nextToken() ; // waste ':'
					StringBuffer sbdata = new StringBuffer() ;
					while (st.hasMoreTokens()){
						sbdata.append(st.nextToken()) ;
					}
					peer_info = addr + ":" + port ;
					data = sbdata.toString() ;
				}
			}
			catch (ClientTimeoutException hcte){
				continue ;
			}
			catch (ClientException hce){
				throw hce ;
			}

			return data ;
		}
	}


	public String get_peer_info(){
		return peer_info ;
	}


	public int print(String data) throws ClientException {
		if (fhid == null){
			throw new ClientException("HTTunnel.Client object is not connected") ;
		}

		execute(
			"write",
			new String [] { fhid, proto },
			data
		) ;

		return 1 ;
	}


	public int close() throws ClientException {
		if (fhid != null){
			execute(
				"close",
				new String [] { fhid }
			) ;
			fhid = null ;

			return 1 ;
		}
	
		return 0 ;
	}


	private String execute(String cmd, String args[]) throws ClientException {
		return execute(cmd, args, null) ;
	}
	
	
	private String execute(String cmd, String args[], String data) throws ClientException {
		StringBuffer furlsb = new StringBuffer(url.toString() + "/" + cmd) ;
		for (int i = 0 ; i < args.length ; i++){
			furlsb.append("/" + args[i]) ;
		}

		HttpURLConnection huc = null ;
		InputStream is = null ;
		StringBuffer rdata = new StringBuffer() ;
		try {
			URL furl = new URL(furlsb.toString()) ;
			huc = (HttpURLConnection)furl.openConnection() ;
			request_callback(huc) ;
			huc.setUseCaches(false) ;
			huc.setAllowUserInteraction(false) ;
			huc.setDoInput(true) ;
			huc.setDoOutput(data != null) ;
			huc.setRequestMethod("POST") ;
			huc.setRequestProperty("Content-Length", 
				(data == null ? "0" : new Integer(data.length()).toString())) ;
			huc.connect() ;

			if (data != null){
				OutputStream os = huc.getOutputStream() ;
				os.write(data.getBytes()) ;
				os.flush() ;
				os.close() ;
			}

			response_callback(huc) ;
			is = huc.getInputStream() ;
			if (huc.getResponseCode() != HttpURLConnection.HTTP_OK){
				throw new ClientException("HTTP error : " + huc.getResponseCode() + 
					" (" + huc.getResponseMessage() + ")") ;
			}

			byte buf[] = new byte[16834] ;
			int len = 0 ;
			while ((len = is.read(buf)) != -1){
				rdata.append(new String(buf, 0, len)) ;
			}
		}
		catch (IOException ioe){
			throw new ClientException(ioe.getClass().getName() + ": " + ioe.getMessage()) ;
		}
		finally {
			if (is != null){
				try {
			     	is.close() ;
				}
				catch (IOException ioe){}
			}
			if (huc != null){
				huc.disconnect() ;
			}
		}

		String content = rdata.toString() ;
		String code = content.substring(0, 3) ;
		if (code.equals("err")){
			throw new ClientException("Apache::HTTunnel error:" + content.substring(3)) ;
		}
		else if (code.equals("okn")){
			return null ;
		}
		else if (code.equals("okd")){
			return content.substring(3) ;
		}
		else if (code.equals("okt")){
			throw new ClientTimeoutException() ;
		}
		else{
			throw new ClientException("Invalid Apache::HTTunnel response code '" + code + "'") ;
		}
	}


	protected void request_callback(HttpURLConnection huc){
	}


	protected void response_callback(HttpURLConnection huc){
	}


	public class ClientException extends Exception {
		ClientException(String msg){
			super(msg) ;
		}
	}


	private class ClientTimeoutException extends ClientException {
		ClientTimeoutException(){
			super("Apache::HTTunnel voluntary timeout") ;
		}
	}
}
