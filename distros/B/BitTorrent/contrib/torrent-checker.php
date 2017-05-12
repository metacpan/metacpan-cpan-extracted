<?
	require("/var/lib/perl/bencode.php");

	// $bencode wird als neue Klasse definiert
	$bencode = new BEncodeLib();

	$src = $argv[1];	  

	// $src bezieht sich auf die .torrent Datei
	$fp = fopen($src,'r'); 
	if (!$fp) die("Error opening connection.");
	$stream = fread($fp,204800);
	fclose($fp);

	// Decodiere den gelesenen Inhalt
	// Im Array $torrent stehen nun viele (un-) wichtige Infos
	$torrent = $bencode->bdecode($stream);
	  
	// Berechne den Infohash
	$infohash = sha1($bencode->bencode($torrent["info"]));
	$infohash = urlencode(pack("H*", $infohash));

	// Erzeuge Announce-String
	$announce = $torrent["announce"];      
	  
	// Erzeuge Tracker-URL
	$parts = parse_url($torrent["announce"]);

	if ($parts["port"] != "") {
		$tracker = "http://".$parts["host"].":".$parts["port"];
	} else {
		$tracker = "http://".$parts["host"];
	}

	// Wenn der Announce-String auf eine PHP Datei verweist, machen wir das auch.
	if (substr($announce, strrpos($announce,"/") + 1) == "announce.php") {
		$scrape = '/scrape.php?info_hash=';
	} else {
		$scrape = '/scrape?info_hash=';
	}


	# hier seeder und leecher infos auslesen

	// Tracker-URL in der Form [url]http://server.com/scrape?info_hash=1234[/url]
	$tracker_url = $tracker.$scrape.$infohash;

	$fp = @fopen($tracker_url, 'r');
	if ($fp) { 
		// Wir lesen nun die relevaten Daten vom Tracker aus...
		$stream = @fread($fp,512000);
		@fclose($fp);

		// ...Decodieren sie...
		$stream = $bencode->bdecode(substr($stream,32));

		#print_r($stream);

		// ...Und erhalten die für uns wichtigen Werte! 
		$seeder		= $stream['complete'];
		$leecher	= $stream['incomplete'];

	};
	
	trim($seeder);
	trim($leecher);
	echo trim("$seeder#$leecher");
	

	# hier alle torrent infos auslesen
	# print_r($torrent);	
	
?> 