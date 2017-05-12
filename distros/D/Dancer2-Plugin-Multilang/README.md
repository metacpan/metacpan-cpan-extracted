NAME
===========

Dancer::Plugin::Multilang - Plugin to manage languages on Dancer2

VERSION
=======

version 1.1.1

DESCRIPTION
===========

A little plugin to create a multilanguage site with routes like /it/... and /en/... with also the SEO headers.

CONFIGURATION
=============

Only needed parameters are the managed languages and the default one (when the language of the user is not managed)

```
plugins: 
  Multilang: 
    languages: ['it', 'en'] 
    default: 'it' 
```

USAGE
=====

Just import it in the app. All the routes will be managed by a before hook that will change them. Do not add internalization on the routes. The plugin will do all the work for you (well... i hope)

In routes you can use the __language__ keyword to retrieve the language and manage it to give back the right content.

AUTHOR
======

Simone Faré
