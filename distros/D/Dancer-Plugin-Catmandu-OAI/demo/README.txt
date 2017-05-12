Setup a demo OAI server
-=-=-=-=-=-=-=-=-=-=-=-

Setup an ElasticSearch server
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

    $ cpanm Dancer Catmandu::OAI Catmandu::Store::ElasticSearch
    $ wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.2.zip
    $ unzip elasticsearch-1.7.2.zip
    $ cd elasticsearch-1.7.2
    $ bin/elasticsearch

Import records
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

   # Delete all the data from the oai store
   $ catmandu drop oai

   # Import some demo data
   $ catmandu import YAML to oai < sample.yml

   # Check if we have data stored
   $ catmandu export oai

Start the Dancer application
-=-=-=-=-=-=-=-=-=-=-=-=-=-= 
* Make sure the elasticsearch server is up and running (see the top of this document)
* Start dancer:

  $ perl ./app.pl

* An OAI server is now running on port 3000.

* Test queries:

  $ curl "http://localhost:3000/oai?verb=Identify"
  $ curl "http://localhost:3000/oai?verb=ListSets"
  $ curl "http://localhost:3000/oai?verb=ListMetadataFormats"
  $ curl "http://localhost:3000/oai?verb=ListIdentifiers&metadataPrefix=oai_dc"
  $ curl "http://localhost:3000/oai?verb=ListRecords&metadataPrefix=oai_dc"
  $ curl "http://localhost:3000/oai?verb=GetRecord&identifier=oai:oai.service.com:oai:pub.uni-bielefeld.de:1857750&metadataPrefix=oai_dc"
