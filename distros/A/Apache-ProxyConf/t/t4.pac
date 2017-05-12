function FindProxyForURL(url, host) {
	if (shExpMatch(host, "www.intranet.playbeing.org")) return "DIRECT";
	if (shExpMatch(host, "www2.intranet.playbeing.org")) return "DIRECT";
	if (shExpMatch(url, "https://*")) return "PROXY 172.16.0.20:3128; PROXY 172.16.0.10:3128";
	return "PROXY 172.16.32.10:3128; PROXY 172.16.16.10:3128";
}
