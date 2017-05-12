#!/usr/bin/env python

import sys
import json

while 1 :
      line = sys.stdin.readline()
      data = json.loads(line.strip())
      print json.dumps(data)
