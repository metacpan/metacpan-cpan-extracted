# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy;

#-----
# When Moose detects an isa violation during attribute assignment it
# throws an exception.  Hopefully Moose won't change its wording....
#
# The actual message names the violated attribute before this text.
#-----
my $moose_diag_rex =
    qr{ does \s+ not  \s+ pass \s+ the  \s+ type \s+ constraint }x;

#-----
# The 'trigger' for 'columns' verifies that attempted settings are positive
# integers.  pod2usage() appears to do different things with I<>/B<>
# tags based on version.  Sometimes it produces *word*, and sometimes just
# word.  Unfortunately this means that we can no longer predict line
# wrapping boundarys.
#-----
my $insufficient_columns_rex =
    qr{
          ~+                                                \r? \n
          \QOops << insufficient columns >>\E               \r? \n
          ~+                                                \r? \n
          \Q  *** Description ***\E                         \r? \n
          \Q    The requested setting of '\E .+?
          \Q' for the 'columns' attribute is not allowed.\E \r? \n

          \s*                                               \r? \n

          \Q  *** Synopsis ***\E                            \r? \n
          \Q      columns:\E                                \r? \n

          \s+ The \s+ \*? columns \*? \s+ attribute \s+
          sets \s+ the \s+ line \s+ width \s+ target \s+
          for \s+ the \s+ Banner \s+ and \s+ for \s+ any \s+
          filled \s+ Sections \. \s+ Values \s+ below \s+
          about \s+ 30 \s+ are \s+ not \s+ practical \.

          \s*                                               \r? \n

          \Q        Builder: _build_columns()\E             \r? \n
          \Q        Default: 78\E                           \r? \n
          \Q        Domain: Positive Integers\E             \r? \n
          \Q        Affects: banner() and filled_section()\E\r? \n
          \Q        Mutability: Read-Write\E                \r? \n

          \s*                                               \r? \n

          \Q  *** Stacktrace ***\E                          \r? \n
      }xs;

#----- The trigger for body_indent verifies non-negatives
my $negative_body_rex =
    qr{
          ~+                                                \r? \n
          \QOops << negative body indentation >>\E          \r? \n
          ~+                                                \r? \n
          \Q  *** Description ***\E                         \r? \n
          \Q    The requested setting of '\E .*?
          \Q' for the 'body_indent' attribute\E
          \s+ is \s+ not \s+ allowed.                       \r? \n
          \s*                                               \r? \n
          \Q  *** Synopsis ***\E                            \r? \n
          \Q      body_indent:\E                            \r? \n

          \s+ \*? body_indent \*? \s+ influences \s+
          the \s+ presentation \s+ of \s+ paragraphs \s+
          created \s+ by \s+ the \s+ Section \s+
          creating \s+ methods \s+ filled\(\) \s+ and \s+
          fixed\(\) \. \s+ Use \s+ \*? body_indent \*? \s+
          to \s+ determine \s+ the \s+ amount \s+ of \s+
          additional \s+ indentation, \s+ beyond \s+
          header_indent, \s+ that \s+ is \s+ applied \s+
          to \s+ Section \s+ paragraphs \. \s*              \r? \n

          \Q        Builder: _build_body_indent()\E         \r? \n
          \Q        Default: 2\E                            \r? \n
          \Q        Domain: Non-negative integers\E         \r? \n
          \Q        Affects: filled_section() and \E
          \Qfixed_section()\E                               \r? \n
          \Q        Mutability: Read-Write\E                \r? \n
          \s*                                               \r? \n
          \Q  *** Stacktrace ***\E                          \r? \n
      }xs;

#----- The trigger for header_indent verifies non-negatives
my $negative_header_rex =
    qr{
          ~+                                                \r? \n
          \QOops << negative header indentation >>\E        \r? \n
          ~+                                                \r? \n
          \Q  *** Description ***\E                         \r? \n
          \Q    The requested setting of '\E .+?
          \Q' for the 'header_indent' attribute is not\E    \r? \n
          \Q    allowed.\E                                  \r? \n
                                                            \r? \n
          \Q  *** Synopsis ***\E                            \r? \n
          \Q      header_indent:\E                          \r? \n

          \s+ Section \s+ Headers \s+ are \s+ indented \s+
          from \s+ the \s+ left \s+ margin \s+ by \s+
          \*? header_indent \*? \s+ spaces \. \s*           \r? \n

          \Q        Builder: _build_header_indent()\E       \r? \n
          \Q        Default: 2\E                            \r? \n
          \Q        Domain: Non-negative Integers\E         \r? \n
          \Q        Affects: header(), filled_section() \E
          \Qfixed_section()\E                               \r? \n
          \Q        Mutability: Read-Write\E                \r? \n
                                                            \r? \n
          \Q  *** Stacktrace ***\E                          \r? \n
      }xs;

#----- The trigger for context verifies a valid context choice, or a CodeRef.
my $invalid_context_rex =
    qr{
          ~+                                                \r? \n
          \QOops << invalid context setting >>\E            \r? \n
          ~+                                                \r? \n
          \Q  *** Description ***\E                         \r? \n
          \Q    The requested setting of '\E .*?
          \Q' for the 'context' attribute\E \s+
          is \s+ not \s+ allowed [.]                        \r? \n
                                                            \r? \n
          \Q  *** Synopsis ***\E                            \r? \n
          \Q      context:\E                                \r? \n

          \s+ The \s+ \*? context \*? \s+ attribute \s+
          controls \s+ the \s+ generation \s+ of \s+ a \s+
          stacktrace \s+ Section \. \s*                     \r? \n

          \Q        Builder: _build_context()\E             \r? \n
          \Q        Default: 'confess'\E                    \r? \n
          \Q        Domain:\E                               \r? \n

          \s*                                               \r? \n

          \Q            'none' - No Section \E
          \Qgenerated.\E                                    \r? \n
          \Q            'die' - Describe where \E
          \QProxy was called.\E                             \r? \n
          \Q            'croak' - Describe where \E
          \QProxy's caller was called.\E                    \r? \n
          \Q            'confess' - Stacktrace, \E
          \Qstarting with Proxy call.\E                     \r? \n
          \Q            'internals' - Complete \E
          \Qstacktrace with Carp::Proxy guts.\E             \r? \n
          \Q            CodeRef - Do it yourself.\E   \r? \n

          \s*                                               \r? \n

          \Q        Affects: add_context()\E                \r? \n
          \Q        Mutability: Read-Write\E                \r? \n

          \s*                                               \r? \n

          \Q  *** Stacktrace ***\E                          \r? \n
      }xs;

#----- The trigger for disposition verifies a valid choice or a CodeRef.
my $invalid_disposition_rex =
    qr{
          ~+                                                \r? \n
          \QOops << invalid disposition setting >>\E        \r? \n
          ~+                                                \r? \n
          \Q  *** Description ***\E                         \r? \n
          \Q    The requested setting of '\E .*?
          \Q' for the 'disposition'\E \s+ attribute \s+
          is \s+ not \s+ allowed [.]                        \r? \n

          \s*                                               \r? \n

          \Q  *** Synopsis ***\E                            \r? \n
          \Q      disposition:\E                            \r? \n

          \s+ The \s+ \*? disposition \*? \s+ attribute \s+
          controls \s+ how \s+ the \s+ exception \s+ is \s+
          thrown \. \s*                                     \r? \n

          \Q        Builder: _build_disposition()\E         \r? \n
          \Q        Default: 'die'\E                        \r? \n
          \Q        Domain:\E                               \r? \n

          \s*                                               \r? \n

          \Q            'return' - No exception \E
          \Qthrown; Proxy returns.\E                        \r? \n
          \Q            'warn' - Carp::Proxy object \E
          \Qpassed to Perl's warn().\E                      \r? \n
          \Q            'die' - Carp::Proxy object \E
          \Qpassed to Perl's die().\E                       \r? \n
          \Q            CodeRef - Do it yourself.\E      \r? \n

          \s*                                               \r? \n

          \Q        Affects: perform_disposition()\E        \r? \n
          \Q        Mutability: Read-Write\E                \r? \n

          \s*                                               \r? \n

          \Q  *** Stacktrace ***\E                          \r? \n
      }xs;

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $attr, $setting ) = @_;

    $cp->$attr( $setting )
        if @_ > 1;

    $cp->filled('Throwing');
    return;
}

sub main {

    throws_ok{ fatal 'handler' }
        qr{
              \A

              ~{78} \s+
              \QFatal << handler >>\E \s+
              ~{78} \s+

              \Q  *** Description ***\E \s+
              \Q    Throwing\E \s+

          }x,
        'Our handler appears to work';

    foreach my $tuple
        (
         #----- as_yaml is Bool; there are no invalid Bools

         #----- banner_title isa Str
         [ banner_title =>
           [[ undef,    'undef',    $moose_diag_rex ],
           ]],

         #----- begin_hook isa Maybe[CodeRef]
         [ begin_hook =>
           [[ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 123,      'Number',   $moose_diag_rex ],
            [ [],       'Aref',     $moose_diag_rex ],
            [ {},       'Href',     $moose_diag_rex ],
           ]],

         #----- body_indent isa Int with a trigger to check negatives
         [ body_indent =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ -1,       'Negative', $negative_body_rex ],
            [ 3.27,     'Float',    $moose_diag_rex ],
           ]],

         #----- columns is an Int with a trigger to check non-positives
         [ columns =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ -1,       'Negative', $insufficient_columns_rex ],
            [ 0,        'Zero',     $insufficient_columns_rex ],
            [ 3.33,     'Float',    $moose_diag_rex ],
           ]],

         #-----
         # context isa Defined with a trigger that wants either a CodeRef
         # or a string that matches one of the defined context settings.
         #-----
         [ context =>
           [[ undef,    'undef',    $moose_diag_rex      ],
            [ {},       'Href',     $invalid_context_rex ],
            [ [],       'Aref',     $invalid_context_rex ],
            [ q(),      'Empty',    $invalid_context_rex ],
            [ q(bogus), 'Non-Set',  $invalid_context_rex ],
           ]],

         #-----
         # disposition isa defined with a trigger that wants either a
         # CodeRef or one of the defined disposition settings.
         #-----
         [ disposition =>
           [[ undef,    'undef',    $moose_diag_rex      ],
            [ {},       'href',     $invalid_disposition_rex ],
            [ q(),      'empty',    $invalid_disposition_rex ],
            [ q(bogus), 'Non-Set',  $invalid_disposition_rex ],
           ]],

         #----- end_hook isa Maybe[CodeRef]
         [ end_hook =>
           [[ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 123,      'Number',   $moose_diag_rex ],
            [ [],       'Aref',     $moose_diag_rex ],
            [ {},       'Href',     $moose_diag_rex ],
           ]],

         #----- exit code isa Int
         [ exit_code =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 4.3,      'Float',    $moose_diag_rex  ],
            [ q(),      'Empty',    $moose_diag_rex  ],
           ]],

         #----- handler_pkgs isa Aref
         [ handler_pkgs =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 123,      'Number',   $moose_diag_rex ],
            [ {},       'Href',     $moose_diag_rex ],
           ]],

         #----- handler_prefix isa Maybe[Str]; everything is valid

         #----- header_indent isa Int with a trigger checking for negatives
         [ header_indent =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ -1,       'Negative', $negative_header_rex ],
            [ 3.27,     'Float',    $moose_diag_rex ],
           ]],

         #----- maintainer isa Str
         [ maintainer =>
           [[ undef,    'undef',    $moose_diag_rex ],
           ]],

         #----- pod_filename is Str
         [ pod_filename =>
           [[ undef,    'undef',    $moose_diag_rex ],
           ]],

         #----- section_title isa Str
         [ section_title =>
           [[ undef,    'undef',    $moose_diag_rex ],
           ]],

         #----- sections isa ArrayRef[ArrayRef]
         [ sections =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 123,      'Number',   $moose_diag_rex ],
            [ {},       'Href',     $moose_diag_rex ],
            [ [ q()],   'Aref_Str', $moose_diag_rex ],
           ]],

         #----- tags isa HashRef
         [ tags =>
           [[ undef,    'undef',    $moose_diag_rex ],
            [ q(),      'Empty',    $moose_diag_rex ],
            [ q(abc),   'String',   $moose_diag_rex ],
            [ 123,      'Number',   $moose_diag_rex ],
            [ [],       'Aref',     $moose_diag_rex ],
           ]],
        ) {

        my( $attr, $todo_list ) = @{ $tuple };

        foreach my $todo (@{ $todo_list }) {

            my( $setting, $descr, $regex ) = @{ $todo };

            #----- customize the moose diagnostic with the attr name
            my $rex = ($regex == $moose_diag_rex)
                ? qr{ $attr .+ $regex }xs
                : $regex;

            #-----
            # Attributes may not be constructed/validated until they
            # are accessed.  We combine construction with access here
            # so that no matter when it validates it eventually throws.
            #-----
            throws_ok
                {
                    no strict 'refs';
                    my $name = join '_', 'error', $attr, $descr;
                    Carp::Proxy->import( $name => { $attr => $setting });
                    $name->('handler');
                }
                $rex,
                "$attr in constructor rejects '$descr' as a setting";

            #-----
            # Here we have the handler attempt to use the Carp::Proxy
            # object's writer-accessor to the attribute to the specified
            # setting.  We expect Moose to perform validation here as well.
            #-----
            throws_ok{ fatal 'handler', $attr, $setting }
                $rex,
                "$attr accessor rejects '$descr' as a setting";
        }
    }

    return;
}
