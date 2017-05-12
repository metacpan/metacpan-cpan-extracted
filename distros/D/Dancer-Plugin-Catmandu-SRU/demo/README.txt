Setup a demo SRU server
-=-=-=-=-=-=-=-=-=-=-=-

Setup an ElasticSearch server
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

    $ cpanm Dancer Catmandu::SRU Catmandu::Store::ElasticSearch
    $ wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.2.zip
    $ unzip elasticsearch-1.7.2.zip
    $ cd elasticsearch-1.7.2
    $ bin/elasticsearch

Import records
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

   # Delete all the data from the oai store
   $ catmandu drop sru

   # Import some demo data
   $ catmandu import YAML to sru < sample.yml

   # Check if we have data stored
   $ catmandu export sru

Start the Dancer application
-=-=-=-=-=-=-=-=-=-=-=-=-=-= 
* Make sure the elasticsearch server is up and running (see the top of this document)
* Start dancer:

  $ perl ./app.pl

* An OAI server is now running on port 3000. 

* Test queries:

  $ curl "http://localhost:3000/sru"
  $ curl "http://localhost:3000/sru?version=1.1&operation=searchRetrieve&query=(_id+%3d+1)"
  $ catmandu convert SRU --base 'http://localhost:3000/sru' --query '(_id = 1)'
