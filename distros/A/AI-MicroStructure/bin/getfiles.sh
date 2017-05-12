mojo get "https://en.wikibooks.org/w/index.php?title=Special:Search&limit=100&offset=0&ns6=0&search=crime" ".mw-search-results" | sed -s "s/\"\/\//\"http:\/\//"  > crime.files.html
