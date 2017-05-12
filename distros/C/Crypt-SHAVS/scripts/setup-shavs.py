""" setup-shavs.py: fetches and unzips the NIST test vectors

1. Creates directories 'BYTE' and 'BIT' for each type of vector
2. Retrieves PDF document describing SHA Validation System

"""

import os, re, urllib, zipfile

PDF = 'SHAVS.pdf'
ZIP = ('shabytetestvectors.zip', 'shabittestvectors.zip')
URL = 'http://csrc.nist.gov/groups/STM/cavp/documents/shs/'

if not os.path.isfile(PDF):
	print 'fetching', PDF, '...'
	urllib.urlretrieve(URL + PDF, PDF)

for z in ZIP:
	if not os.path.isfile(z):
		print 'fetching', z, '...'
		urllib.urlretrieve(URL + z, z)

	if re.search('byte', z): to = 'BYTE'
	else:                    to = 'BIT'
	if not os.path.isdir(to):
		os.mkdir(to)

	zip = zipfile.ZipFile(z, 'r')
	print 'unzipping', z, 'to', to, '...'
	for n in zip.namelist():
		f = open(os.path.join(to, n), 'w')
		f.write(zip.read(n))
		f.close()
