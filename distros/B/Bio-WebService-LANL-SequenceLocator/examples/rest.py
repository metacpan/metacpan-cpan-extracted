#!/usr/bin/env python2
from urllib2 import Request, urlopen, URLError
from urllib  import urlencode
import json

request = Request('https://indra.microbiol.washington.edu/locate-sequence/within/hiv')
data = urlencode({
    'sequence': [
        'SLYNTVAVLYYVHQR',
        'TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG'
    ]
}, True);

try:
    response = urlopen(request, data)
    text     = response.read()
    results  = json.loads(text)
except URLError, e:
    print 'Request failed: ', e
except ValueError, e:
    print 'Decoding JSON failed: ', e
finally:
    if results == None:
        exit(1)

print results
