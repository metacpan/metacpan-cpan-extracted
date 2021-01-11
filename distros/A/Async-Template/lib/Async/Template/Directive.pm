package Async::Template::Directive;

#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 08.10.2012

use strict;
use warnings;
use base 'Template::Directive';


our $VERSION = 0.14;
our $DYNAMIC = 0 unless defined $DYNAMIC;



sub event_proc {
   my ( $self, $block ) = @_;
   return << "EOF";
sub {
   my \$context = shift || die "template sub called without context\\n";
   my \$stash   = \$context->stash;
   my \$out  = \$context->event_output;
   my \$_tt_error;
   eval { BLOCK: {
$block
   } };
   if (\$@) {
      \$_tt_error = \$context->catch(\$@, \$context->event_output);
      if( \$_tt_error->type eq 'return' )
         { \$context->do_return( \$\$out ); }
      else
         { die \$_tt_error; }
   }
   return '';
}
EOF
}


sub event_finalize {
   return << "END";
   \$context->event_done(\$out);
END
}


sub event_cb {
   return << "END";
   sub { \$context->event_done( \@_ == 1 ? \$_[0] : \\\@_ ) }
END
}


# TODO: remove this function after refactoring back $out to $output
sub return {
    return "\$context->throw('return', '', \$out);";
}


sub ident_eventify {
   my ( $self, $ident, $event_cb ) = @_;
   my $last = $#{$ident};
   my $params = $ident->[$last];
   $params = '[]' if $params eq '0';
   die 'event must be function call' unless ']' eq substr $params, -1;
   my $cb = $event_cb || $self->event_cb;
   my $comma = $params =~ /^\[\s*\]$/ ? '' : ',';
   $params =~ s/.$/$comma $cb \]/;
   $ident->[$last] = $params;
}


sub async_call {
   my ( $self, $resvar, $ident ) = @_;
   my ( $RES, $CB ) = (0,1);

   $resvar = '[' . join(', ', @$resvar) . ']' if $resvar;
   $self->ident_eventify($ident, "\$async_cb");
   my $expr = $self->ident( $ident );

   return << "END";

   my \$rescb = [ undef, undef ];
   my \$async_cb = sub {
     if( \$rescb->[$CB] )
       { \$rescb->[$CB]->(\@_); }
     else
       { \$rescb->[$RES] = \\\@_ }
   };
   my \$await_cb = sub {
     my \$cb = pop;
     if( \$rescb->[$RES] )
       { \$cb->( \@{\$rescb->[$RES]} ); }
     else
       { \$rescb->[$CB] = \$cb; }
   };
   \$stash->set($resvar, \$await_cb);
   $expr;
END
}


#------------------------------------------------------------------------
# event_template($block)
#------------------------------------------------------------------------

sub event_template {
   my ($self, $block) = @_;
#   $block = pad($block, 2) if $PRETTY;

   return "sub { return '' }" unless $block =~ /\S/;

   my $res = << "EOF"  ;
$block
EOF

   return $self->event_proc($res);
}


#------------------------------------------------------------------------
# define_event($res,$expr,$block)
#------------------------------------------------------------------------

sub define_event {
   my ( $self, $resvar, $expr, $event ) = @_;
   $resvar = '[' . join(', ', @$resvar) . ']' if $resvar;
   $event = $self->event_proc( $event );
   return << "END";
   
   # EVENT
   my \$event = $event;
   my \$ev = \$context->event_top();
   \$context->event_push( {
      resvar => $resvar,
      event => \$event,
   } );
   $expr;
   return '';
END
}


#------------------------------------------------------------------------
# include(\@nameargs)                    [% INCLUDE template foo = bar %] 
#          # => [ [ $file, ... ], \@args ]    
#------------------------------------------------------------------------

sub include {
   my ($self, $nameargs, $event) = @_;
   $self->process( $nameargs, $event, 'localize me!' );
}


#------------------------------------------------------------------------
# process(\@nameargs)                    [% PROCESS template foo = bar %] 
#         # => [ [ $file, ... ], \@args ]
#------------------------------------------------------------------------

sub process {
   my ($self, $nameargs, $event, $localize) = @_;
   my ($file, $args) = @$nameargs;
   my $hash = shift @$args;
   $file = $self->filenames($file);
   $file .= @$hash ? ', { ' . join(', ', @$hash) . ' }' : ', {}';
   $localize ||= '';
   $event = $self->event_proc( $event );
   return << "EOF";

   # EVENT PROCESS
   my \$event = $event;
   \$context->event_push( {
      event => \$event,
   } );
   \$context->process_enter($file,\'$localize\');
   return '';
EOF
}


#------------------------------------------------------------------------
# event_wrapper(\@nameargs, $block, $tail, $is_blk_ev)
# \@nameargs => [ [ $file, ... ], \@args ] ]
#                                     [% WRAPPER file1 + file2 foo=bar %]
#                                     ...
#                                     [% END %]
#------------------------------------------------------------------------

sub event_wrapper {
   my ($self, $nameargs, $block, $tail, $is_blk_ev) = @_;

   my ($files, $args) = @$nameargs;
   my $hash = $args->[0];
   push(@$hash, "'content'", '${$capture_output}');
   my $inclargs .= '{ ' . join(', ', @$hash) . ' }';
   my $name = '[' . join(', ', @$files) . ']';

   $block = pad($block, 1) if $Template::Directive::PRETTY;

   if( !$is_blk_ev ) {
      $block .= $self->event_finalize;
   }

   my $iteration = << "___EOF";
      # WRAPPER LOOP
      my \$capture_output = \$context->event_output;
      my \$next_output = '';
      \$context->set_event_output( \\\$next_output );
      \$out = \$next_output;
      if( scalar \@\$wrapper_files ) {
         my \$file = pop \@\$wrapper_files;
         \$context->event_push( {
            event => \$iteration,
         } );
         \$context->process_enter(\$file, $inclargs, 'localize me');
      } else {
         my \$event_top = \$context->event_top();
         my \$pop_output = \$event_top->{push_output};
         \${\$pop_output} .= \${\$capture_output};
         \$context->set_event_output( \$pop_output );
         \$out = \$pop_output;
$tail
      }
___EOF

   $iteration = $self->event_proc( $iteration );

   my $capture = << "___EOF";
      # WRAPPER CONTENT CAPTURE
      my \$push_out = \$context->event_output;
      my \$event_top = \$context->event_top();
      \$event_top->{push_output} = \$push_out;
      my \$capture_out = '';
      \$context->set_event_output( \\\$capture_out );
      \$out = \\\$capture_out;
      \$context->event_push( {
         resvar => undef,
         event  => \$iteration,
      } );
$block
___EOF

return << "___EOF";
   my \$wrapper_files = $name;
   my \$iteration; \$iteration = $iteration;
$capture
___EOF
}


#------------------------------------------------------------------------
# event_while($expr, $block, $tail, $label)            [% WHILE x < 10 %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------

sub event_while {
   my ($self, $expr, $block, $tail, $label) = @_;
#   $block = pad($block, 2) if $PRETTY;
   $label ||= 'LOOP';

   my $while_max = $Template::Directive::WHILE_MAX;

   $block = << "EOF";
   if( --\$context->event_top()->{failsafe} && ($expr) ) {
      \$context->event_push( {
	 resvar => undef,
	 event  => \$event,
      } );
$block
   } else {
      die "WHILE loop terminated (> $while_max iterations)\\n"
	 unless \$context->event_top()->{failsafe};
$tail
   }
EOF

   $block = $self->event_proc($block);

   return << "EOF";

   # EVENT $label DECLARE
   my \$event;
   \$event =
$block 
;

   # EVENT $label STARTUP
   \$context->event_top()->{failsafe} = $while_max;
   \$event->( \$context );
   return '';
EOF
}


#------------------------------------------------------------------------
# event_for($target, $list, $args, $block, $tail)
#                                           [% FOREACH x = [ foo bar ] %]
#                                              ...
#                                           [% END %]
#------------------------------------------------------------------------

sub event_for {
   my ($self, $target, $list, $args, $block, $tail, $label) = @_;
   # $args is not used in original code
   $label ||= 'LOOP';

   # vars: value, list, getnext, error, oldloop

   my ($loop_save, $loop_set, $loop_restore, $setiter);
   if ($target) {
      $loop_save    = 'eval { $evtop->{oldloop} = ' . $self->ident(["'loop'"]) . ' }';
      $loop_set     = "\$stash->{'$target'} = \$evtop->{value}";
      $loop_restore = "\$stash->set('loop', \$evtop->{oldloop})";
   }
   else {
      $loop_save    = '$stash = $context->localise()';
#      $loop_set     = "\$stash->set('import', \$evtop->{value}) "
#                      . "if ref \$value eq 'HASH'";
      $loop_set     = "\$stash->get(['import', [\$evtop->{value}]]) "
                      . "if ref \$evtop->{value} eq 'HASH'";
      $loop_restore = '$stash = $context->delocalise()';
  }
#    $block = pad($block, 3) if $PRETTY;

   $block = << "EOF";
   my \$evtop = \$context->event_top();
   if( \$evtop->{getnext} ) {
      (\$evtop->{value}, \$evtop->{error}) =
	 \$evtop->{list}->get_next();
   } else {
      \$evtop->{getnext} = 1;
   }
   if( ! \$evtop->{error} ) {
$loop_set;
      \$context->event_push( {
         resvar => undef,
         event  => \$event,
      } );
do{
$block
};
   } else {
$loop_restore;
      \$evtop->{error} = 0
	 if \$evtop->{error} &&
	    \$evtop->{error} eq Template::Constants::STATUS_DONE;
      die \$evtop->{error}
	 if \$evtop->{error};
$tail
   }
EOF

   $block = $self->event_proc($block);

   return << "EOF";

   # EVENT $label DECLARE
   my \$event;
   \$event =
$block 
;

   # EVENT $label STARTUP
   my \$evtop = \$context->event_top();
   \$evtop->{list} = $list;
   unless (UNIVERSAL::isa(\$evtop->{list}, 'Template::Iterator')) {
      \$evtop->{list} = 
         Template::Config->iterator(\$evtop->{list})
         || die \$Template::Config::ERROR, "\\n"; 
   }
   (\$evtop->{value}, \$evtop->{error}) = \$evtop->{list}->get_first();
$loop_save;
   \$stash->set('loop', \$evtop->{list});
   \$event->( \$context );
   return '';
EOF

}


#------------------------------------------------------------------------
# event_switch($expr, \@case)                              [% SWITCH %]
#                                                          [% CASE foo %]
#                                                             ...
#                                                          [% END %]
#------------------------------------------------------------------------

sub event_switch {
   my ($self, $expr, $case, $tail) = @_;
   my @case = @$case;
   my ($evented, $calltail,$pct, $match, $block, $default);
   my $caseblock = '';

   $default = pop @case;

   $calltail = <<EOF;
\$context->event_push( {
   event => \$event_tail,
} );
EOF

   foreach $case (@case) {
      $match = $case->[0];
      $block = $case->[1];
      $evented = $case->[2];
#      $block = pad($block, 1) if $PRETTY;

      $pct = $evented ? \$calltail : \'';

      $caseblock .= <<EOF;
\$_tt_match = $match;
\$_tt_match = [ \$_tt_match ] unless ref \$_tt_match eq 'ARRAY';
if (grep(/^\\Q\$_tt_result\\E\$/, \@\$_tt_match)) {
${$pct} $block 
   last EVENTSWITCH;
}
EOF

   } # foreach

   if( defined $default ) {
      if( 'ARRAY' eq ref $default ) {
         #$default = 'my $event = ' . $self->event_proc( $default->[0] ) . ';';
         $default = $default->[0];
      }
      $caseblock .= $calltail . $default
   }
   $tail = 'my $event_tail = ' . $self->event_proc( $tail ) . ';';
#    $caseblock = pad($caseblock, 2) if $PRETTY;

return <<EOF;

# EVENT SWITCH
$tail
do {
   my \$_tt_result = $expr;
   my \$_tt_match;
   EVENTSWITCH: {
$caseblock
   }
};
    
   \$event_tail->( \$context );
EOF
}


#------------------------------------------------------------------------
# event_if_directive($expr, $resvar, $evexpr, $expr, $tail)
#------------------------------------------------------------------------

sub event_if_directive {
   my ( $self, $resvar, $evexpr, $expr, $tail ) = @_;

   $resvar = '[' . join(', ', @$resvar) . ']' if $resvar;
   $tail = $self->event_proc( $tail );

   return << "END";
my \$event_tail = $tail;
if( $expr ) {
   $evexpr;
   \$context->event_push( {
      resvar => $resvar,
      event => \$event_tail,
   } );
} else {
   \$event_tail->( \$context );
}
END

}


#------------------------------------------------------------------------
# event_if($expr, $block, $else, $tail, $is_blk_ev)
#------------------------------------------------------------------------

sub event_if {
   my ($self, $expr, $block, $else, $tail, $is_blk_ev ) = @_;
   my $label ||= 'IF';

   my @else = $else ? @$else : ();
   $else = pop @else;
#   $block = pad($block, 1) if $PRETTY;

   $tail = $self->event_proc( $tail );

   my $output = << "END";
my \$event_tail = $tail;
END

   if( $is_blk_ev ) {
      $block = << "END";
\$context->event_push( {
   event => \$event_tail,
} );
$block;
return '';
END
   }

   $output .= "if ($expr) {\n$block\n}\n";

   foreach my $elsif (@else) {
      ($expr, $block, $is_blk_ev) = @$elsif;
      if( $is_blk_ev ) {
         $block = << "END";
\$context->event_push( {
   event => \$event_tail,
} );
$block;
return '';
END
         }
#      $block = pad($block, 1) if $PRETTY;
      $output .= "elsif ($expr) {\n$block\n}\n";
   }

   if (defined $else) {
      $block = $else;
      if( 'ARRAY' eq ref $else && 'ev' eq $else->[1] ) {
         $block = $else->[0];
         $block = << "END";
\$context->event_push( {
   event => \$event_tail,
} );
$block;
return '';
END
      }
#      $else = pad($else, 1) if $PRETTY;
      $output .= "else {\n$block\n}\n";
   }

   $output .= << "END";
\$event_tail->( \$context );
END

   return $output;

}


# WRNING: overloading only due to '${$out}' instead '$output'
#------------------------------------------------------------------------
# capture($name, $block)
#------------------------------------------------------------------------

sub capture {
    my ($self, $name, $block) = @_;

    if (ref $name) {
        if (scalar @$name == 2 && ! $name->[1]) {
            $name = $name->[0];
        }
        else {
            $name = '[' . join(', ', @$name) . ']';
        }
    }
#    $block = pad($block, 1) if $PRETTY;

    return <<EOF;

# CAPTURE
\$stash->set($name, do {
    my \$output = ''; my \$out = \\\$output;
$block
    \${\$out};
});
EOF

}


#------------------------------------------------------------------------
# event_capture($name, $block)
#------------------------------------------------------------------------

sub event_capture {
   my ($self, $name, $block, $tail) = @_;

   if (ref $name) {
      if (scalar @$name == 2 && ! $name->[1]) {
         $name = $name->[0];
      }
      else {
         $name = '[' . join(', ', @$name) . ']';
      }
   }
#   $block = pad($block, 1) if $PRETTY;

   #$tail = $self->event_proc($tail);

   my $on_capture = << "EOF";
      my \$event_top = \$context->event_top();
      my \$capture_var = \$event_top->{capture_var};
      my \$push_out = \$event_top->{push_output};
      my \$capture_out = \$context->event_output;
      \$context->set_event_output( \$push_out );
      \$stash->set( \$capture_var, \$\$capture_out );
      \$out = \$push_out;
      #\$context->event_done();
      #my \$tail =
$tail
;
#      \$tail->( \$context );
EOF

   $on_capture = $self->event_proc( $on_capture );

   return << "EOF"

      my \$push_out = \$context->event_output;
      my \$capture_out = '';
      \$context->set_event_output( \\\$capture_out );
      \$out = \\\$capture_out;
      my \$on_capture =
$on_capture;
      my \$event_top = \$context->event_top();
      \$event_top->{push_output} = \$push_out;
      \$event_top->{capture_var} = $name;
      \$context->event_push( {
         resvar => undef,
         event  => \$on_capture,
      } );

$block
EOF
}

1;
