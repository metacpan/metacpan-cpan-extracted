#!/bin/bash

## url_base : base url to use for query-string arguments
url_base="http://www.deutschestextarchiv.de/demo/cab/query";

if test "$#" -eq 0 -o "$1" = "-h" -o "$1" = "--help" ; then
  cat <<EOF >&2

 Usage: $0 URL_OR_QUERY_STRING INFILE [CURL_ARGS]

 Examples:
   $0 "${url_base}?a=default&fmt=json" FILE.json -o out.json
   $0 "?a=default&fmt=json" FILE.json -o out.json

EOF
  exit 1
fi

url="$1"; shift
infile="$1"; shift;

##-- prepend base URL if required
case "$url" in
    "?"*)
	url="${url_base}${url}"
	;;
    *)
	;;
esac

##-- guess content type
case "$infile" in
    *xml|*XML)
	ctype="text/xml; charset=utf8"
	;;
    *tei|*TEI)
	ctype="text/tei+xml; charset=utf8"
	;;
    *tcf|*TCF)
	ctype="text/tcf+xml; charset=utf8"
	;;
    *json|*JSON)
	ctype="application/json; charset=utf8"
	;;
    *yaml|*YAML|*yml|*YML)
	ctype="text/x-yaml; charset=utf8"
	;;
    *bin|*BIN|*sto|*STO)
	ctype="application/octet-stream"
	;;
    *)
	ctype="text/plain; charset=utf8"
	;;
esac

exec curl -X POST -sSH "Content-Type: $ctype" --data-binary @"$infile" -L --post301 --post302 --post303 "$@" "$url"
