use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; package CGI::Application::Plus::Util

# same as the original, here just for compatibility
; sub load_tmpl
   { my $s = shift
   ; my ($tmpl_file, @extra_params) = @_
   # add tmpl_path to path array of one is set, otherwise add a path arg
   ; if (my $tmpl_path = $s->tmpl_path)
      { my $found = 0
      ; for( my $x = 0
           ; $x < @extra_params
           ; $x += 2
           )
         { if (   $extra_params[$x] eq 'path'
              and ref $extra_params[$x+1]
              and ref $extra_params[$x+1] eq 'ARRAY'
              )
            { unshift @{$extra_params[$x+1]}, $tmpl_path
            ; $found = 1
            ; last
            }
         }
      ; push ( @extra_params
             , path => [ $tmpl_path ]
             )
             unless $found
      }
   ; require HTML::Template
   ; my $t = HTML::Template->new_file( $tmpl_file
                                     , @extra_params
                                     )
   ; return $t
   }


# statements from now on are needed just when testing
# and they are never used in real job

; sub dump
   { my $s = shift
   ; $s->page .= qq(Run-mode: "${\$s->runmode}"\n)
   ; $s->page .= "\nQuery Parameters:\n"
   ; foreach my $p ( sort $s->query->param() )
      { my $data_str = "'"
                     . join "', '" , $s->query->param($p)
                     ."'"
      ; $s->page     .= "\t$p => $data_str\n"
      }
   ; $s->page .= "\nQuery Environment:\n"
   ; foreach my $k ( sort keys %ENV )
      { $s->page .= "\t$k => '".$ENV{$k}."'\n"
      }
   }

; sub dump_html
   { my $s = shift
   ; $s->page .= qq(<P><B>Run-mode:</B> ${\$s->runmode}</P>\n)
   ; $s->page .= "<P><B>\nQuery Parameters:<B><BR>\n<OL>\n"
   ; foreach my $p ( sort $s->query->param() )
      { my $data_str = "'"
                     . join "', '" , $s->query->param($p)
                     ."'"
      ; $s->page     .= "<LI> $p => $data_str\n"
      }
   ; $s->page .= "</OL>\n</P>\n";
   ; $s->page .= "<P><B>\nQuery Environment:</B><BR>\n<OL>\n"
   ; foreach my $ek ( sort keys %ENV )
      { $s->page .= "<LI> <B>$ek</B> => ".$ENV{$ek}."\n"
      }
   ; $s->page .= "</OL>\n</P>\n";
   }



; 1

__END__
