<style>
div.slide { min-width: 900px; }
</style>


<h1 style="font-family: monospace; padding-top:2em;">App::SlideServer</span></h1>

<br>

<div style="text-align:left; margin: 2em;">
  Follow Along at:<br>
  <a href="https://nrdvana.net/slides/app-slideserver">nrdvana.net/slides/app-slideserver</a><br>
  <br>
  Source:<br>
  <a href="https://github.com/nrdvana/perl-App-SlideServer" target="_blank">github.com/nrdvana/perl-App-SlideServer</a><br>
</div>

<center>
Michael Conrad<br>
mike@nrdvana.net<br>
CPAN: NERDVANA
</center>

## Features

  * Write markdown, present as a slide show
  * Multiple connections, synchronized
  * Multiple control connections
  * Run locally or from Internet
  * Live updates as you edit
  * Simple design
  * Slides can operate without server

<pre class=notes>
  If all you know is markdown, that's enough

  Cool presentation mode
  Multiple device control, like Keynote

  low complexity, high flexibility
  easy to publish slides without a server
</pre>

## Design

  * Tech Stack - Mojo, jQuery, HTML, CSS
  * Single Perl Module, easy to subclass
  * ES5 JavaScript, no tooling needed
  * Perl backend serves slides
  * JavaScript frontend renders slides

## Design, Backend

  * Commandline "bin/slide-server"
  * Mojolicious App::SlideServer
    * Load slides.md or slides.html
    * Fix sloppy html shorthands
    * Serve page and slides to frontend
    * Relay websocket events

## Design, Frontend

  * Page initiates websocket
  * Presenter navigation relays messages through websocket
  * Viewers receive events from presenter
  * Viewers load slide HTML
  * Viewers resize the HTML to fit the viewport

## HTML Structure

```
<body>
  <div class="slides">
    <div class="slide">
      <ul class="auto-step">
        <li>...
        <li>...
      </ul>
      <pre class="notes"> ... </pre>
    </div>
  </div>
</body>
```

## Markdown Structure

<div style="padding: 0 20%; font-size: 150%">
  <pre><code>
    ## Heading 2
    
      * Item 1
      * Item 2
      * Item 3
    
    &lt;pre class=notes>
       ...
    &lt;/pre>
    
  </code></pre>
</div>

## A Complete Example

<iframe style="width: 700px; height: 600px; background-color: white;"
  src="slides.txt">
</iframe>

## Deploying to a Server

<pre><code data-step="1-1">
 # Build the Image
 $ docker build -t slideserver -f share/Dockerfile .
</code></pre>

<pre><code data-step="2-2">
 # Build the Image
 $ docker build -t slideserver -f share/Dockerfile .
 
 # Create a Container
 $ docker create --name myslides -v $PWD:$PWD -w $PWD -p 80 .
</code></pre>

<pre><code data-step="3">
 # Build the Image
 $ docker build -t slideserver -f share/Dockerfile .
 
 # Create a Container
 $ docker create --name myslides -v $PWD:$PWD -w $PWD -p 80 .
 
 # Run it
 $ docker start myslides;
 $ docker logs --follow myslides
</code></pre>

<pre class=notes>
  makes docker image 'slideserver'
  uses current App::SlideServer on cpan
  makes docker container 'myslides'
  uses current dir slides.md or .html
</pre>

## Deploying under Traefik

<pre><code data-step=1-1>
 $ docker create --name=slideserver --restart=always \
    app-slideserver:latest
</code></pre>

<pre><code data-step=2-2>
 $ docker create --name=slideserver --restart=always \
    --restart=always \
    -e APP_SLIDESERVER_PRESENTER_KEY=REDACTED \
    -w /app \
    -v $PWD/slides.md:/app/slides.md \
    -v $PWD/public:/app/public \
    app-slideserver:latest
</code></pre>

<hr>

```
$ docker create --name=slideserver --restart=always\
  --hostname=nrdvana.net --net=traefik-net --ip=172.18.0.36 \
  -e APP_SLIDESERVER_PRESENTER_KEY=REDACTED \
  -w /app -v $PWD/slides.md:/app/slides.md -v $PWD/public:/app/public \
  --label 'traefik.enable=true' \
  --label 'traefik.http.middlewares.slideserver1.redirectScheme.scheme=https' \
  --label 'traefik.http.middlewares.slideserver2.redirectRegex.regex=(.*)/slides/app-slideserver$' \
  --label 'traefik.http.middlewares.slideserver2.redirectRegex.replacement=${1}/slides/app-slideserver/' \
  --label 'traefik.http.middlewares.slideserver3.stripprefix.prefixes=/slides/app-slideserver' \
  --label 'traefik.http.routers.slideserver.entryPoints=https' \
  --label 'traefik.http.routers.slideserver.rule=(Host(`nrdvana.net`,`www.nrdvana.net`) && PathPrefix(`/slides/app-slideserver`))' \
  --label 'traefik.http.routers.slideserver.middlewares=slideserver1@docker,slideserver2@docker,slideserver3@docker' \
  --label 'traefik.http.routers.slideserver.priority=15' \
  --label 'traefik.http.routers.slideserver.tls=true' \
  --label 'traefik.http.routers.slideserver.tls.certresolver=le' \
  --label 'traefik.http.routers.slideserver.tls.domains[0].main=nrdvana.net' \
  --label 'traefik.http.routers.slideserver.tls.domains[0].sans=www.nrdvana.net' \
  --label 'traefik.http.routers.slideserver_http.entryPoints=http' \
  --label 'traefik.http.routers.slideserver_http.rule=(Host(`nrdvana.net`,`www.nrdvana.net`) && PathPrefix(`/slides/app-slideserver`))' \
  --label 'traefik.http.routers.slideserver_http.middlewares=slideserver1@docker,slideserver2@docker,slideserver3@docker' \
  --label 'traefik.http.routers.slideserver_http.priority=15' \
  --label 'traefik.http.services.slideserver.loadbalancer.server.port=80' \
  --label 'traefik.http.services.slideserver.loadbalancer.server.scheme=http' \
  app-slideserver:latest
```

## Future Work

  * More options for static page rendering
  * Color scheme controls in UI
  * GNU Screen integration
  * More robust auto-update
  * Better width/height automatic layout

<pre class=notes>
  static pages - inline images and js for local
  presenter should choose color scheme, users override
  live terminal to screen session
</notes>

