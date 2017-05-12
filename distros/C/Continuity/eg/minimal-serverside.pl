#!/usr/bin/perl

use strict;
use Continuity;

Continuity->new( port => 8080 )->loop;

sub main {
  my ($r) = @_;
  $r->print(<<'  END');
    <html>
      <head>
        <script type="text/javascript" src="/jquery.js"></script>
        <script type="text/javascript">

          function listenLoop(s) {
            $.get('/', {
                result: s
              },
              function(v){
                var result;
                try { result = eval(v) } catch(e) { result = e.message }
                listenLoop(result);
              }
            );
          }

          $(function(){
            listenLoop();
          });
        </script>
      </head>
      <body>
        <h1>Hello</h1>
      </body>
    </html>
  END
  while(1) {
    $r->next;
    print STDERR $r->param('result') . "\n";
    print "> ";
    my $cmd = <>;
    # $r->send_headers(
      # "HTTP/1.1 200\r\n",
      # "Content-type: text/javascript\r\n\r\n");
    $r->print($cmd);
  }
}

