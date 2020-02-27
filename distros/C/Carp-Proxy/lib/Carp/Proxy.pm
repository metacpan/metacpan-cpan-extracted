# -*- cperl -*-
package Carp::Proxy;
use warnings;
use strict;
use 5.010;

our $VERSION = '0.16';

use Moose;

has( 'arg',
     documentation    => q(Perl's $ARG (AKA $_) at proxy invocation),
     is               => 'ro',
     isa              => 'Any',
     required         => 1,
    );

has( 'as_yaml',
     documentation    => q(Render message as YAML dump of Carp::Proxy object),
     is               => 'rw',
     isa              => 'Bool',
     lazy             => 1,
     builder          => '_build_as_yaml',
   );

has( 'banner_title',
     documentation    => q(The first word(s) in the banner (at top of message)),
     is               => 'rw',
     isa              => 'Str',
     lazy             => 1,
     builder          => '_build_banner_title',
   );

has( 'begin_hook',
     documentation    => q(Callback before handler is launched),
     is               => 'rw',
     isa              => 'Maybe[CodeRef]',
     lazy             => 1,
     builder          => '_build_begin_hook',
   );

has( 'body_indent',
     documentation    => q(paragraph indent (beyond <header_indent>)),
     is               => 'rw',
     isa              => 'Int',
     builder          => '_build_body_indent',
     trigger          => \&_validate_body_indent,
   );

has( 'child_error',
     documentation    => q(Perl's $CHILD_ERROR (AKA $?) at proxy invocation),
     is               => 'ro',
     isa              => 'Any',
     required         => 1,
    );

has( 'columns',
     documentation    => q( Controls width of banner and filled() paragraphs ),
     is               => 'rw',
     isa              => 'Int',
     lazy             => 1,
     builder          => '_build_columns',
     trigger          => \&_validate_columns,
   );

has( 'context',
     documentation    => q( Stacktrace verbosity/inclusion in message ),
     is               => 'rw',
     isa              => 'Defined',
     lazy             => 1,
     builder          => '_build_context',
     trigger          => \&_validate_context,
   );

has( 'disposition',
     documentation    => q( Throwing semantics ),
     is               => 'rw',
     isa              => 'Defined',
     lazy             => 1,
     builder          => '_build_disposition',
     trigger          => \&_validate_disposition,
   );

has( 'end_hook',
     documentation    => q( Callback just before disposition ),
     is               => 'rw',
     isa              => 'Maybe[CodeRef]',
     lazy             => 1,
     builder          => '_build_end_hook',
   );

has( 'eval_error',
     documentation    => q(Perl's $EVAL_ERROR (AKA $@) at proxy invocation),
     is               => 'ro',
     isa              => 'Any',
     required         => 1,
    );

has( 'exit_code',
     documentation    => q(exit-code harvested by OS when this process dies),
     is               => 'rw',
     isa              => 'Int',
     lazy             => 1,
     builder          => '_build_exit_code',
   );

has( 'fq_proxy_name',
     documentation    => q( Fully-Qualified Proxy-Name (with pkg:: prefix)),
     is               => 'rw',
     isa              => 'Str',
     required         => 1,
   );

has( 'handler_name',
     documentation    => q(The name of the handler requested by the user),
     is               => 'ro',
     isa              => 'Str',
     required         => 1,
    );

has( 'handler_pkgs',
     documentation    => q(Search for handler subroutines in these pkgs),
     is               => 'rw',
     isa              => 'ArrayRef',
     lazy             => 1,
     builder          => '_build_handler_pkgs',
     traits           => ['Array'],
     handles          =>
     {
      append_handler_package  => 'push',
      prepend_handler_package => 'unshift',
      list_handler_pkgs       => 'elements',
     },
    );

has( 'handler_prefix',
     documentation    => q( Prefix applied to <handler_name> before lookup ),
     is               => 'rw',
     isa              => 'Maybe[Str]',
     lazy             => 1,
     builder          => '_build_handler_prefix',
   );

has( 'header_indent',
     documentation    => q( Indent from left margin for paragraph headers ),
     is               => 'rw',
     isa              => 'Int',
     lazy             => 1,
     builder          => '_build_header_indent',
     trigger          => \&_validate_header_indent,
   );

has( 'maintainer',
     documentation    => q( Responsible party's email, phone ),
     is               => 'rw',
     isa              => 'Str',
     lazy             => 1,
     builder          => '_build_maintainer',
   );

has( 'numeric_errno',
     documentation    => q(Perl's $ERRNO (AKA $!) at proxy invocation (0+$!)),
     is               => 'ro',
     isa              => 'Maybe[Num]',
     required         => 1,
    );

has( 'pod_filename',
     documentation    => q(The search for synopsis() POD is in this file),
     is               => 'rw',
     isa              => 'Str',
     lazy             => 1,
     builder          => '_build_pod_filename',
   );

has( 'proxy_filename',
     documentation    => q(The filename of the function requesting the proxy ),
     is               => 'ro',
     isa              => 'Str',
     required         => 1,
   );

has( 'proxy_name',
     documentation    => q(The subname of the generated proxy function),
     is               => 'ro',
     isa              => 'Str',
     required         => 1,
    );

has( 'proxy_package',
     documentation    => q(The userland package that requested the proxy),
     is               => 'ro',
     isa              => 'Str',
     required         => 1,
    );

has( 'section_title',
     documentation    => q( Default title for section header ),
     is               => 'rw',
     isa              => 'Str',
     lazy             => 1,
     builder          => '_build_section_title',
   );

has( 'sections',
     documentation    => q( List of filled/fixed/raw section requests ),
     is               => 'rw',
     isa              => 'ArrayRef[ArrayRef]',
     traits           => ['Array'],
     handles          =>
     {
      append_section  => 'push',
      prepend_section => 'unshift',
      list_sections   => 'elements',
     },
     builder          => '_build_sections',
   );

has( 'string_errno',
     documentation    => q(Perl's $ERRNO (AKA $!) at proxy invocation (''.$!)),
     is               => 'ro',
     isa              => 'Maybe[Str]',
     required         => 1,
    );

has( 'tags',
     documentation    => q( Tag-Value store for exception-related user-data ),
     is               => 'rw',
     isa              => 'HashRef',
     lazy             => 1,
     builder          => '_build_tags',
   );

no Moose;
__PACKAGE__->meta->make_immutable;

use Config;
use Cwd        qw( abs_path );
use English    qw( -no_match_vars );
use Sub::Name  qw( subname );
use overload   '""' => \&_overload_stringification;
use Pod::Usage qw( pod2usage );
use Readonly;
use YAML::XS   qw( Dump );

#-----
# We use an internal proxy to throw our own errors.  It cannot be defined
# until later, but this lets us use bareword invocation.
#-----
use subs qw( error );

Readonly::Scalar my $NEWLINE => ($OSNAME =~ / win /xi) ? "\r\n" : "\n";

my @VALID_CONTEXT_STRINGS = qw( none die croak confess internals );
my $VALID_CONTEXT_REX = _fixed_string_rex( @VALID_CONTEXT_STRINGS );

my @VALID_DISPOSITION_STRINGS = qw( return warn die );
my $VALID_DISPOSITION_REX = _fixed_string_rex( @VALID_DISPOSITION_STRINGS );

#----- Some symbolic constants for indexing the list returned by caller()
my $CALLER_PACKAGE;
my $CALLER_FILENAME;
my $CALLER_LINE;
my $CALLER_SUBROUTINE;
BEGIN {
    Readonly::Scalar $CALLER_PACKAGE    => 0;
    Readonly::Scalar $CALLER_FILENAME   => 1;
    Readonly::Scalar $CALLER_LINE       => 2;
    Readonly::Scalar $CALLER_SUBROUTINE => 3;
}

sub _overload_stringification { return $_[0]->render_message; }

sub _build_as_yaml         { return 0;                      }
sub _build_banner_title    { return 'Fatal';                }
sub _build_begin_hook      { return undef;                  }
sub _build_body_indent     { return 2;                      }
sub _build_columns         { return 78;                     }
sub _build_context         { return 'confess';              }
sub _build_disposition     { return 'die';                  }
sub _build_end_hook        { return undef;                  }
sub _build_exit_code       { return 1;                      }
sub _build_handler_pkgs    { return [];                     }
sub _build_handler_prefix  { return undef;                  }
sub _build_header_indent   { return 2;                      }
sub _build_maintainer      { return '';                     }
sub _build_pod_filename    { return $_[0]->proxy_filename;  }
sub _build_proxy_name      { return 'fatal';                }
sub _build_section_title   { return 'Description';          }
sub _build_sections        { return [];                     }
sub _build_tags            { return {};                     }

sub _validate_body_indent {
    my( $self, $indent ) = @_;

    error 'negative_body_indentation', $indent
        if $indent < 0;

    return;
}

sub _cp_negative_body_indentation {
    my( $cp, $indent ) = @_;

    $cp->_disallowed_setting( 'body_indent', $indent );

    return;
}

sub _validate_columns {
    my( $self, $columns ) = @_;

    error 'insufficient_columns', $columns
        if $columns <= 0;

    return;
}

sub _cp_insufficient_columns {
    my( $cp, $columns ) = @_;

    $cp->_disallowed_setting( 'columns', $columns );

    return;
}

sub _validate_context {
    my( $self, $context ) = @_;

    error 'invalid_context_setting', $context
        if 'CODE' ne ref $context
        and $context !~ $VALID_CONTEXT_REX;

    return;
}

sub _cp_invalid_context_setting {
    my( $cp, $context ) = @_;

    $cp->_disallowed_setting( 'context', $context );

    return;
}

sub _validate_disposition {
    my( $self, $disposition ) = @_;

    error 'invalid_disposition_setting', $disposition
        if 'CODE' ne ref $disposition
        and $disposition !~ $VALID_DISPOSITION_REX;

    return
}

sub _cp_invalid_disposition_setting {
    my( $cp, $disposition ) = @_;

    $cp->_disallowed_setting( 'disposition', $disposition );

    return;
}

sub _validate_header_indent {
    my( $self, $indent ) = @_;

    error 'negative_header_indentation', $indent
        if $indent < 0;

    return;
}

sub _cp_negative_header_indentation {
    my( $cp, $indent ) = @_;

    $cp->_disallowed_setting( 'header_indent', $indent );

    return;
}

BEGIN {
    Readonly::Scalar my $POD_USAGE_SPECIFIC_SECTION => 99;

    sub _disallowed_setting {
        my( $cp, $attr, $value ) = @_;

        my $req = _display_code_or_string( $value );

        $cp->filled(<<"EOF");
The requested setting of '$req' for the '$attr' attribute is not allowed.
EOF

        $cp->synopsis( -verbose  => $POD_USAGE_SPECIFIC_SECTION,
                       -sections => ["ATTRIBUTES/$attr"],
                     );
        return;
    }
}

sub _display_code_or_string {
    my( $value ) = @_;

    my $req
        =  not( defined $value ) ? '(undef)'
        :  ref( $value )         ? 'REF: ' . ref( $value )
        :  $value;

    return $req;
}

sub _fixed_string_rex {
    my( @strings ) = @_;

    my $alternations = join ' | ', @strings;

    return qr{
                 \A
                 (?: $alternations )
                 \z
             }x;
}

sub import {
    my( $class, @proxy_attrlist_pairs ) = @_;

    my %by_proxyname;

    #-----
    # If there are no args then the user is implicitly requesting a
    # proxy named 'fatal'.
    #-----
    if (not @proxy_attrlist_pairs) {

        $by_proxyname{ $class->_build_proxy_name() } = {};
    }
    #----- Just one argument names a proxy with default attributes
    elsif ( 1 == @proxy_attrlist_pairs ) {

        $by_proxyname{ $proxy_attrlist_pairs[0] } = {};
    }
    #----- Otherwise there had better be pairs...
    elsif ( @proxy_attrlist_pairs % 2 ) {

        error 'unmatched_proxy_arglist', @proxy_attrlist_pairs;
    }
    else {

        %by_proxyname = @proxy_attrlist_pairs;
    }

    while(my($proxy_name, $attributes) = each %by_proxyname ) {

        $class->_create_proxy( $proxy_name, $attributes );
    }

    return;
}

sub _cp_unmatched_proxy_arglist {
    my( $cp, @mismatched_list ) = @_;

    my $count = @mismatched_list;

    my $pairings = '';
    while( my( $proxy_name, $attr_val_hashref ) =
           splice @mismatched_list, 0, 2
         ) {

        $attr_val_hashref = ''
            if not defined $attr_val_hashref;

        $pairings .= "$proxy_name => $attr_val_hashref" . $NEWLINE;
    }

    $cp->filled( <<"EOF" );
Proxy creation arguments must come in (proxy, arglist) pairs.  Each pair
should take the form:

    proxy name => hashref

An odd number of arguments were provided:

    $pairings
EOF
    return;
}

sub _create_proxy {
    my( $class, $proxy_name, $requested_attributes, ) = @_;

    #----- caller(1) should be import() called from userland
    my  ( $user_pkg,       $user_fname      ) = (caller 1)
        [ $CALLER_PACKAGE, $CALLER_FILENAME ];

    my $fq_proxy_name = $user_pkg . '::' . $proxy_name;

    #-----
    # The *configuration* builtin handler returns a reference to this
    # closure hash.
    #-----
    my %attrs = ( proxy_filename => $user_fname,
                  proxy_name     => $proxy_name,
                  proxy_package  => $user_pkg,
                  fq_proxy_name  => $fq_proxy_name,
                  %{ $requested_attributes },
                );

    my $proxy_coderef = _define_proxy( $class, \%attrs );

    #-----
    # Name the coderef so that caller() reports the name instead of ANON.
    #-----
    subname( $fq_proxy_name, $proxy_coderef );

    #----- Install the proxy in userland
    {
        no strict 'refs';
        *{ $fq_proxy_name } = $proxy_coderef;
    }

    return;
}

sub _define_proxy {
    my( $class, $attrs ) = @_;

    return sub {
        my( $handler_name, @optional_arguments ) = @_;

        return $attrs
            if $handler_name eq '*configuration*';

        my $cp = $class->new({
                              arg           => $ARG,              # $_
                              child_error   => $CHILD_ERROR,      # $?
                              eval_error    => $EVAL_ERROR,       # $@
                              numeric_errno => 0 + $ERRNO,        # $!
                              string_errno  => '' . $ERRNO,       # $!
                              handler_name  => $handler_name,
                              %{ $attrs },
                             });

        $cp->append_handler_package( $cp->proxy_package );

        my $begin_hook = $cp->begin_hook;
        $begin_hook->( $cp )
            if defined $begin_hook;

        $cp->call( $handler_name, @optional_arguments );

        $cp->add_context;

        my $end_hook = $cp->end_hook;
        $end_hook->( $cp )
            if defined $end_hook;

        return $cp->perform_disposition;
    };
}

sub perform_disposition {
    my( $self ) = @_;

    my $disposition = $self->disposition;

    if ( not defined $disposition ) {

        error 'unknown_disposition', $self;
    }
    elsif ( 'CODE' eq ref $disposition ) {

        return $disposition->( $self );
    }
    elsif ( 'warn' eq $disposition ) {

        ## no critic( ErrorHandling::RequireCarping )
        warn $self;
        return ();
    }
    elsif ( 'die' eq $disposition ) {

        local $ERRNO = $self->exit_code;

        ## no critic( ErrorHandling::RequireCarping )
        die $self;
    }
    elsif ( 'return' ne $disposition ) {

        error 'unknown_disposition', $self;
    }

    return $self;
}

sub _cp_unknown_disposition {
    my( $cp, $original_cp ) = @_;

    my $disp = _display_code_or_string( $original_cp->disposition );

    my $possibilities = join ' ', @VALID_DISPOSITION_STRINGS;

    _unsupported_attribute_value( $cp,
                                  $original_cp,
                                  'disposition',
                                  $disp,
                                  $possibilities );

    return;
}

sub _unsupported_attribute_value {
    my( $cp, $original_cp, $attr, $val, $possibilities ) = @_;

    $cp->filled(<<"EOF");
The program has encountered an error.  The developers attempted to
diagnose the error but they made a mistake during the diagnosis.
There are now two errors.  You should complain!

The secondary error is an attempt to use an unsupported value for
an attribute.

    $attr: '$val'

The supported values for $attr, beyond a CodeRef, are:

    $possibilities
EOF

    $cp->_describe_primary_error( $original_cp );
    return;
}

sub _describe_primary_error {
    my( $self, $original_cp ) = @_;

    $self->contact_maintainer();

    $self->filled(<<'EOF', 'Primary Error' );
The remaining sections attempt to describe the original error.
EOF

    my $st = $original_cp->section_title;
    foreach my $section ( $original_cp->list_sections ) {

        my $primary_title = defined( $section->[2] )
            ? $section->[2]
            : $st;

        #----- Turn 'Description' into 'Primary Description' etc.
        $primary_title =~ s/ ^ /Primary /x;

        $self->append_section([ $section->[0],
                                $section->[1],
                                $primary_title ]);
    }

    return;
}

sub add_context {
    my( $self ) = @_;

    my $context = $self->context;

    if    ( not defined        $context ) { error 'unknown_context', $self; }
    elsif ( 'CODE'      eq ref $context ) { $context->($self);              }
    elsif ( 'die'       eq     $context ) { $self->_die_context();          }
    elsif ( 'croak'     eq     $context ) { $self->_croak_context();        }
    elsif ( 'confess'   eq     $context ) { $self->_confess_context();      }
    elsif ( 'internals' eq     $context ) { $self->_internals_context();    }
    elsif ( 'none'      ne     $context ) { error 'unknown_context', $self; }

    return;
}

sub _die_context {
    my( $self ) = @_;

    my $caller_index = $self->_find_proxy_frame();

    my( $file, $line, $subr ) = $self->_file_line_subr( $caller_index );

    $self->_single_frame_context( $file, $line, $subr );

    return;
}

sub _croak_context {
    my( $self ) = @_;

    #-----
    # 'croak' semantics asks us to go back one additional frame from
    # where the proxy was called.
    #-----
    my $caller_index = 1 + $self->_find_proxy_frame();

    my( $file, $line, $subr ) = $self->_file_line_subr( $caller_index );

    #-----
    # If the proxy was invoked from top-level code then there is no
    # caller to report.  In this case we fallback to 'die' semantics.
    #-----
    if (not defined $file) {

        --$caller_index;

        ( $file, $line, $subr ) = $self->_file_line_subr( $caller_index );
    }

    $self->_single_frame_context( $file, $line, $subr );
    return;
}

sub _confess_context {
    my( $self ) = @_;

    my $caller_index = $self->_find_proxy_frame();

    $self->_multi_frame_context( $caller_index );
    return;
}

sub _internals_context {
    my( $self ) = @_;

    $self->_multi_frame_context( undef );
    return;
}

sub _cp_unknown_context {
    my( $cp, $original_cp ) = @_;

    my $context = _display_code_or_string( $original_cp->context );

    my $possibilities = join ' ', @VALID_CONTEXT_STRINGS;

    _unsupported_attribute_value( $cp,
                                  $original_cp,
                                  'context',
                                  $context,
                                  $possibilities );

    return;
}

sub _find_proxy_frame {
    my( $self ) = @_;

    my $fqp = $self->fq_proxy_name;

    my $frame = 1;
    while (1) {

        my( $sub ) = (caller $frame)[ $CALLER_SUBROUTINE ];

        error 'no_proxy_frame', $self
            if not defined $sub;

        last
            if $sub eq $fqp;

        ++$frame;
    }

    return $frame
}

sub _cp_no_proxy_frame {
    my( $cp, $original_cp ) = @_;

    my $frames = '';
    for( my $i=0;   1;   ++$i ) {

        my( $subr ) = (caller $i)[ $CALLER_SUBROUTINE ];

        last
            if not defined $subr;

        $frames .= "  $i => $subr" . $NEWLINE;
    }

    my $proxy = $original_cp->fq_proxy_name;

    $cp->filled(<<"EOF");
The callstack does not appear to contain a frame for the proxy.  This is
an internal error.  The proxy name that was the target of the search is:

    $proxy

The following list contains the stackframe index and the associated subrotine
name:
EOF

    $cp->fixed( $frames, '' );

    $cp->_describe_primary_error( $original_cp );
    return;
}

sub _file_line_subr {
    my( $self, $caller_index ) = @_;

    my( $file, $line, $subr );

    eval{
        ( $file, $line, $subr ) =
            (caller 1 + $caller_index)[
                                       $CALLER_FILENAME,
                                       $CALLER_LINE,
                                       $CALLER_SUBROUTINE,
                                      ];
    };

    return $EVAL_ERROR ? () : ($file, $line, $subr);
}

sub _single_frame_context {
    my( $self, $file, $line, $subr ) = @_;

    my $whence = $self->_make_frame_report( $file, $line, $subr );

    $self->fixed( $whence, 'Exception' );

    return;
}

sub _section_indent {
    my( $self ) = @_;

    return $self->body_indent + $self->header_indent;
}

sub _make_frame_report {
    my( $self, $file, $line, $subr ) = @_;

    #----- We want to report just the basename of the subroutine (no pkg)
    $subr =~ s/\A .+ :: //x;

    #-----
    # If the filename is short enough then it will appear on the same line
    # as the subr and the line number.  If the filename is too long then
    # we put the filename on the next line and indent by an extra amount.
    # The extra amount is an additional body_indent, or 2 spaces if there
    # is no body indent.
    #-----
    my $file_indent = $self->body_indent || 2;

    my $section_indent = $self->_section_indent;

    my $whence = "$subr called from line $line of";

    #-----
    # If we were to add the filename to whence then it would need to be
    # separated by a space (+ 1).  Also we need to account for the fact
    # that the report will form the body of a fixed() section, so there
    # will be a section indent in front of whence.
    #-----
    my $length_with_file =
        $section_indent + length( $whence ) + 1 + length( $file );

    $whence .= ($self->columns >= $length_with_file )
        ? ' '
        : $NEWLINE . (' ' x $file_indent);

    $whence .= $file . $NEWLINE;

    return $whence;
}

sub _multi_frame_context {
    my( $self, $starting_frame ) = @_;

    #-----
    # We have to add an extra frame to account for ourselves, unless
    # they want 'internals', in which case they want everything.
    #-----
    $starting_frame = defined( $starting_frame )
        ? 1 + $starting_frame
        : 0;

    my $stacktrace = '';
    for( my $frame = $starting_frame;   1;   ++$frame ) {

        my( $file, $line, $subr ) = $self->_file_line_subr( $frame );

        last
            if not defined $file;

        $stacktrace .= $self->_make_frame_report( $file, $line, $subr );
    }

    $self->fixed( $stacktrace, 'Stacktrace' );

    return;
}


sub filled {
    my( $self, $content, $title ) = @_;

    $self->append_section([ 'filled_section', $content, $title ]);
    return;
}

sub fixed {
    my( $self, $content, $title ) = @_;

    $self->append_section([ 'fixed_section', $content, $title ]);
    return;
}

sub raw {
    my( $self, $content ) = @_;

    $self->append_section([ 'raw_section', $content ]);
    return;
}

sub filled_section {
    my( $self, $content, $title ) = @_;

    return ''
        if $content =~ /\A \s* \z/x;

    my $buffer  = $self->header( $title );
    my $columns = $self->columns;

    my @paragraphs = split / (?: \r? \n){2,} /x, $content;

    my $section_indent = ' ' x $self->_section_indent;

    foreach my $p (@paragraphs) {

        #----- You need words to make a paragraph
        next
            if $p =~ /\A \s* \z/x;

        $buffer .= _fill_paragraph( $section_indent, $columns, $p );
    }

    return $buffer;
}

sub _fill_paragraph {
    my( $indent, $columns, $text ) = @_;

    #----- Whitespace, where carriage-returns and newlines don't count.
    my( $leading_ws ) = $text =~ /\A ( [^\r\n\S]* ) /x;

    #----- Any non-tab whitespace (vertical tabs, formfeeds etc) become spaces
    $leading_ws =~ tr/\t/ /c;
    $leading_ws = $indent . _expand_tabs( $leading_ws );

    my @words  = split ' ', $text;
    my $line   = $leading_ws . shift @words;
    my $buffer = '';

    foreach my $w (@words) {

        if (( length( $line ) + 1 + length( $w )) <= $columns) {

            $line .= ' ' . $w;
        }
        else {

            $buffer .= $line . $NEWLINE;

            #----- Always eat one word, even if it exceeds columns
            $line = $leading_ws . $w;
        }
    }

    $buffer .= $line . $NEWLINE . $NEWLINE;
    return $buffer;
}

BEGIN{
    Readonly::Scalar my $TAB => 8;

    sub _expand_tabs {
        my( $text ) = @_;

        #----- Keep replacing the first tab as long as there are tabs
        1 while $text =~ s{ \A ( [^\t]* ) \t }
                          { $1 . (' ' x ($TAB - (length($1) % $TAB))) }xe;

        return $text;
    }
}

sub fixed_section {
    my( $self, $content, $title ) = @_;

    my $buffer = $self->header( $title );
    my $indent = ' ' x $self->_section_indent;

    my @lines = split / \r? \n /x, $content;
    foreach my $l (@lines) {

        $buffer
            .= $indent
            .  _expand_tabs( $l )
            .  $NEWLINE;
    }

    $buffer =~ s/ \s+ \z//x;
    $buffer .= $NEWLINE . $NEWLINE;

    return $buffer;
}

sub raw_section {
    my( $self, $content ) = @_;

    return $content;
}

sub _cp_missing_identifier {
    my( $cp ) = @_;

    $cp->filled(<<'EOF');
The 'name' argument for identifier_presentation() is empty or undef.
EOF
    return;
}

sub identifier_presentation {
    my( $class, $name ) = @_;

    error 'missing_identifier'
        if not( defined $name )
        or not( length  $name );

    $name =~ s/ _ / /xg;
    $name =~ s{ ([[:lower:]]) ([[:upper:]]) }{ "$1 $2" }xge;
    $name = lc $name;

    return $name;
}

sub header {
    my( $self, $title ) = @_;

    if ( defined $title ) {

        return ''
            if not length $title;
    }
    else {

        $title = $self->section_title;
    }

    my $header
        = (' ' x $self->header_indent)
        . "*** ${title} ***$NEWLINE";

    return $header;
}

sub banner {
    my( $self ) = @_;

    my $standout = ('~' x $self->columns) . $NEWLINE;

    my $banner
        = $standout
        . $self->banner_title
        . ' << '
        . $self->identifier_presentation( $self->handler_name )
        . ' >>'
        . $NEWLINE
        . $standout;

    return $banner;
}

sub synopsis {
    my( $self, @tag_value_pairs ) = @_;

    error 'odd_synopsis_augmentation', @tag_value_pairs
        if @tag_value_pairs % 2;

    my $buffer = '';
    my $fd = _open_string_as_file( \$buffer );

    eval {
        pod2usage( -input   => $self->pod_filename,
                   -output  => $fd,
                   -exitval => 'NOEXIT',
                   -verbose => 0,
                   @tag_value_pairs );
    };

    if ($EVAL_ERROR) {

        my $ignore = print {$fd} <<"EOF";
Unable to create synopsis section from file '@{[ $self->pod_filename ]}':

$EVAL_ERROR
EOF
    }

    _close_string_file( $fd );

    $self->fixed( $buffer, 'Synopsis' );
    return;
}

sub _open_string_as_file {
    my( $string_ref ) = @_;

    open my( $fd ), '>', $string_ref
        or error 'cannot_open_string';

    return $fd;
}

sub _cp_cannot_open_string {
    my( $cp ) = @_;

    $cp->filled( <<"EOF" );
Unable to create a file descriptor using a string as the storage medium.
EOF
    $cp->errno_section;
    return;
}

sub _close_string_file {
    my( $fd ) = @_;

    close $fd
        or error 'cannot_close_string';

    return;
}

sub _cp_cannot_close_string {
    my( $cp ) = @_;

    $cp->filled( <<"EOF" );
Unable to close a file-descriptor that points to a string buffer as the
storage medium.
EOF
    $cp->errno_section;
    return;
}

sub _cp_odd_synopsis_augmentation {
    my( $cp, @tag_value_pairs ) = @_;

    my $tv_report = '';
    while( @tag_value_pairs >= 2 ) {

        my( $t, $v ) = splice @tag_value_pairs, 0, 2;

        $tv_report .= "$t => $v" . $NEWLINE;
    }

    $tv_report .= "$tag_value_pairs[0] =>" . $NEWLINE;

    $cp->filled( <<"EOF" );
The synopsis() method allows users to supplement pod2usage() arguments
with tag-value pairs.  The supplied arguments did not come in pairs; there
are an odd number.

    $tv_report
EOF
    return;
}

sub usage {
    my( $self ) = @_;

    for(my $index = $self->_find_proxy_frame();   1;   ++$index ) {

        my( $subr ) = (caller $index)[ $CALLER_SUBROUTINE ];

        error 'no_usage_documentation', $self
            if not defined $subr;

        #----- Discard any package qualifiers
        $subr =~ s/ \A .* :: //x;

        my $handler = 'usage_' . $subr;

        my $where = $self->_locate_handler( $handler );

        next
            if not $where;

        $where->( $self );
        last;
    }

    return;
}

sub _cp_no_usage_documentation {
    my( $cp, $original_cp ) = @_;

    $cp->filled(<<"EOF");
There was an error.  The developers caught the error and attempted to
describe it.  Part of the description was supposed to be provided by a
"usage" subroutine.  Unfortunately they forgot to define the usage
subroutine.  Now there are two errors.  You shoud complain!
EOF

    my $prefix = $original_cp->handler_prefix;

    $prefix //= '(undef)';

    $cp->fixed(<<"EOF", 'Missing Handler - Secondary Error');
handler_pkgs:   @{[ join ' : ', $original_cp->list_handler_pkgs ]}
handler_prefix: $prefix
EOF

    $cp->_describe_primary_error( $original_cp );
    return;
}

BEGIN{
    Readonly::Scalar my $ONE_BYTE    => 8;
    Readonly::Scalar my $SIGNAL_MASK => 0x7F;
    Readonly::Scalar my $CORE_DUMP   => 0x80;

    sub decipher_child_error {
        my( $cp ) = shift;

        my $child_error = ( @_ and defined( $_[0] ) and $_[0] =~ /\A \d+ \z/x )
            ? shift
            : $cp->child_error;

        if ( 0 == $child_error ) {

            $cp->filled( 'The child process completed normally (exit code 0).',
                         'Process Succeeded' );
            return;
        }

        my $signal = $child_error &  $SIGNAL_MASK;
        if ($signal) {

            my @names = split ' ', $Config{sig_name};
            my @nums  = split ' ', $Config{sig_num};

            my %by_num;
            @by_num{ @nums } = @names;

            my $sig_name = $by_num{ $signal };

            my $msg
                = 'The child process was terminated by '
                . ((defined $sig_name)
                    ? "SIG$sig_name (signal $signal)."
                    : "signal $signal.")
                . (($child_error & $CORE_DUMP)
                   ? '  There was a core dump.'
                   : '');

            $cp->filled( $msg, 'Process terminated by signal' );
            return;
        }

        my $exit_code = $child_error >> $ONE_BYTE;

        $cp->filled( "The child process terminated with exit code $exit_code.",
                     'Process returns failing status' );
        return;
    }
}

sub filename {
    my( $cp, $file, $title ) = @_;

    $title = 'Filename'
        if not defined $title;

    $cp->_abs_path_section( $file, $title );
    return;
}

sub directory {
    my( $cp, $dir, $title ) = @_;

    $title = 'Directory'
        if not defined $title;

    $cp->_abs_path_section( $dir, $title );
    return;
}

sub _abs_path_section {
    my( $cp, $entry, $title ) = @_;

    my $path;

    #-----
    # On *nix abs_path() appears to return undef if it has trouble.  On
    # Windows it appears to throw.  Docs are ambiguous.
    #-----
    eval{ $path = abs_path( $entry ); };

    $path = $entry
        if not( defined $path )
        or $EVAL_ERROR;

    $cp->fixed( $path, $title );

    return;
}

sub errno_section {
    my( $cp, $title ) = @_;

    my $string_errno = $cp->string_errno;

    return
        if not( defined $string_errno )
        or not( length  $string_errno );

    $title = 'System Diagnostic'
        if not defined $title;

    $cp->filled( $string_errno, $title );
    return;
}

sub render_message {
    my( $self ) = @_;

    return Dump( $self )
        if $self->as_yaml;

    my $buffer = $self->banner;

    my @sections = $self->list_sections;
    foreach my $s (@sections) {

        my( $meth, @args ) = @{ $s };

        $buffer .= $self->$meth( @args );
    }
    return $buffer;
}

sub call {
    my( $self, $handler, @args ) = @_;

    my $where = $self->_locate_handler( $handler );

    error 'embarrassed_developers', $self, $handler
        if not $where;

    $where->( $self, @args );

    return;
}

sub _locate_handler {
    my( $self, $handler_name ) = @_;

    my $coderef;

    if ($handler_name =~ /\A [*] ( .+ ) [*] \z/x) {

        my $builtin = $1;
        $coderef = $self->can( '_builtin_' . $builtin );
    }
    else {

        my $handler_prefix  = $self->handler_prefix;

        my @prefixes = (defined $handler_prefix)
            ? ( $handler_prefix )
            : ( '_cp_', '_', '' );

        PKG: foreach my $pkg ($self->list_handler_pkgs) {

            foreach my $pre (@prefixes) {

                $coderef = $pkg->can( $pre . $handler_name );

                last PKG
                    if $coderef;
            }
        }
    }

    return $coderef;
}

sub _cp_embarrassed_developers {
    my( $cp, $original_cp, $handler ) = @_;

    $cp->filled(<<"EOF");
There was an error.  The developers caught the error and attempted to
pass diagnosis off to a handler.  Unfortunately they forgot to define
the handler.  Now there are two errors.  You shoud complain!
EOF

    my $prefix = $original_cp->handler_prefix;

    $prefix //= '(undef)';

    $prefix = q('')
        if not length $prefix;

    $cp->fixed(<<"EOF", 'Missing Handler - Secondary Error');
handler_name:   $handler
handler_pkgs:   @{[ join ' : ', $original_cp->list_handler_pkgs ]}
handler_prefix: $prefix
EOF

    $cp->_describe_primary_error( $original_cp );
    return;
}

sub _builtin_internal_error {
    my( $cp, @args ) = @_;

    $cp->filled( "@args" )
        if @args;

    $cp->contact_maintainer;

    return;
}

sub _builtin_assertion_failure {
    my( $cp, $description, $hashref ) = @_;

    my $boilerplate = <<"EOF";
An assertion has failed.  This indicates that the internal state of
the program is corrupt.
EOF

    $boilerplate .= $NEWLINE . $description
        if defined( $description )
        and length( $description );

    $cp->filled( $boilerplate );

    $cp->contact_maintainer;

    if (defined( $hashref ) and keys %{ $hashref }) {

        my $yaml = Dump( $hashref );

        $cp->fixed( $yaml, 'Salient State (YAML)' );
    }

    $cp->context( 'confess' );

    return;
}

sub contact_maintainer {
    my( $cp ) = @_;

    my $maintainer = $cp->maintainer;

    $cp->fixed( $maintainer, 'Please contact the maintainer' )
        if length $maintainer;

    return;
}

BEGIN {

    #-----
    # The real intent of this eval is to add another frame to the
    # callstack so that create_proxy() installs error() into the
    # Carp::Proxy package.
    #-----
    eval {
        __PACKAGE__->import( 'error',
                             {
                              banner_title => 'Oops',
                              context      => 'internals',
                             });
    };

    ## no critic( ErrorHandling::RequireCarping )
    die $EVAL_ERROR if $EVAL_ERROR;
}


1;

__END__

=pod

=begin stopwords

accessor
accessors
AnnoCPAN
arg
arg-checking
ArrayRef
ArrayRefs
boolean
boundarys
builtin
BUILTIN
callstack
camelCasedIdentifiers
CodeRef
CPAN
CPAN's
customizable
dereferences
filename
HashRef
hashref
initializations
invoker
invoker-upward
Liebert
logfile
multi-line
parameterized
perldoc
perlvar
prepended
Proxys
regex
repeatability
runtime
rw
stackframe
stackframes
Stackframes
stacktrace
stacktraces
STDERR
stringification
tradeoff
undef
whitespace
YAML

=end stopwords

=head1 NAME

Carp::Proxy - Diagnostic delegation

=head1 SYNOPSIS

    use Carp::Proxy;
 
    fatal 'handler_subroutine', @optional_arguments
        if not $assertion;
 
    sub handler_subroutine {
        my( $proxy_object, @optional_arguments ) = @_;
 
        $proxy_object->filled( 'explanation' );
        return;
    }

=head1 DESCRIPTION

B<Carp::Proxy> is a framework for throwing exceptions.  The goal is to
couple the small lexical footprint of the B<die()> statement with
support for comprehensive error messages.  Good diagnostics pay for
themselves; let's make them easier to produce.

Error messages in Perl are commonly coded with idioms like:

    die 'explanation'
        if not $assertion;

The idiom is attractive when the explanation is simple.  If an
explanation grows to more than a few words, or if it requires
calculation, then the surrounding flow becomes disrupted.  The
solution, of course, is to offload failing assertions to a subroutine.

Subroutines that perform diagnosis, compose error messages and throw
exceptions tend to have repeated code at the beginning and end, with
unique content somewhere in the middle.  B<Carp::Proxy> proposes a
wrapper subroutine, called a Proxy, to factor out the repeated sections.

    fatal 'user_subroutine'
        if not $assertion;

Proxys, like B<fatal()>, serve as elaborate, customizable replacements
for B<warn()>, B<die()> and members of the B<Carp::> family like
B<confess()>.  If we look at B<warn()>, B<die()>, B<confess()> and the
others, we notice that they are all just different variations on two themes:

    - Add locational context to a user-supplied message.
    - Throw some kind of exception.

B<Carp::Proxy> parameterizes the two themes into attributes of an
exception object that is created whenever a Proxy is called.  The
Proxy passes the object to a user-defined "Handler" subroutine which
is responsible for constructing the diagnostic message.  When the
Handler returns, the Proxy optionally adds "Context" (a stacktrace) to
the message and performs "Disposition", typically by calling B<die()>.

When the object is constructed it captures the state of Perl's error
variables, for later examination by the Handler.  The object provides
methods that aid in message composition.  Attributes control message
formatting, stacktrace generation and how Disposition will be handled.

The object overloads Perl's stringification operator with a message
rendering method, causing uncaught exceptions to be nicely formatted.
Exceptions that are caught can be modified and re-thrown.

=head1 WE ARE THE 99%

B<Carp::Proxy> has a long list of features, but getting started is easy.
All you need for most day-to-day work is the Proxy and two methods:

    fatal()   The (default) Proxy.
    filled()  Auto-formatting message builder method.
    fixed()   Pre-formatted message builder method.

Use B<fatal()> wherever you currently use B<die()>.  Your Handler should
compose the diagnostic text using the L<filled()|/filled> and/or
L<fixed()|/fixed> methods.

=head1 SAMPLE OUTPUT

The formatted messages produced by the Proxy start off with a
"Banner".  The Banner includes a title and the name of the Handler.
As the Banner is the first thing seen by users, it is helpful if the
Handler name conveys a terse description of the situation.

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Fatal: << cannot overwrite >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Following the Banner are a series of "Sections" containing paragraphs of
descriptive text.  Each Section is introduced by a "Header" sub-title
that is wrapped in *** stars ***.

      *** Description ***
        The destination file already exists.  An attempt was made
        to overwrite it, but the attempt failed.  This might have
        happened because of permission problems, or possibly if
        the destination is not a file (i.e. a directory or link
        or something else).
 
        Either remove the destination manually, or choose a
        different destination.
 
      *** Destination Filename ***
        /home/isaac/muse/content
 
      *** ls(1) output ***
        -r--r--r-- 1 isaac users 21626 Aug  5 17:22 content
 
      *** System Diagnostic ***
        Permission denied
 
      *** Stacktrace ***
        fatal called from line 273 of /usr/bin/cantu
	set_output called from line 244 of /usr/bin/cantu
	main called from line 24 of /usr/bin/cantu

Here is the corresponding Handler code.  Note that most of the Handler's
body is dedicated to producing message content; there is very little
overhead.  Handlers are easy to write.

    sub cannot_overwrite {
        my( $cp, $filename ) = @_;

        $cp->filled(<<"EOF");
    The destination file already exists.  An attempt was made to
    overwrite it, but the attempt failed.  This might have happened
    because of permission problems, or possibly if the destination
    is not a file (i.e. a directory or link or something else).

    Either remove the destination manually, or choose a different
    destination.
    EOF
        $cp->filename( $filename, 'Destination Filename' );
        $cp->fixed( qx{ /bin/ls -ld $filename }, 'ls(1) output' );
        $cp->errno_section;
        return;
    }

=head1 EXPORTS

B<Carp::Proxy> defines an exception class.  Depending on the arguments
supplied to B<use()>, B<Carp::Proxy> also generates Proxy subroutines
for export.  The generation part is important: B<Carp::Proxy>
implements the B<import()> method as a function factory.

Proxy customization is performed by supplying a HashRef of
B<attribute =E<gt> parameter> pairs for each desired Proxy.
The arguments to B<use()> or B<import()> look like this:

    proxy_name1 =>
        {
         attribute => parameter,
         ...
         },

    proxy_name2 =>
        {
         attribute => parameter,
         ...
        },
    ...

If there is only one argument, i.e. a proxy-name key with no corresponding
value, then an empty HashRef, C<{}>, where all attributes assume defaults,
is implied.

Here are some examples:

    #-----
    # All three of these 'use' statements generate and export a
    # Proxy named fatal() with defaults for all attributes.
    #-----
    use Carp::Proxy;
    use Carp::Proxy 'fatal';
    use Carp::Proxy fatal => {};
 
    #-----
    # This statement is the same as all of the above, except
    # that now the Proxy is named error() instead of fatal().
    #-----
    use Carp::Proxy 'error';
 
    #-----
    # Here we export two proxys, oops() and warning(), each with
    # different sets of attributes.
    #-----
    use Carp::Proxy oops    => { context      => 'internals' },
                    warning => { banner_title => 'Warning',
                                 disposition  => 'warn'      };
 
    #----- No exports.  Class definition only.
    use Carp::Proxy ();

The no-export form is desirable if you want the class definition for your
own purposes, or if Proxy attributes need to be established at runtime.
You can invoke L<import()|/import>, at any time, to build Proxy subroutines.

    use Carp::Proxy ();
    ...
    Carp::Proxy->import( expire => { end_hook => $log_me });

=head1 PROXY INVOCATION

 Usage:
    <proxy> $handler, @optional_arguments;

The default L<proxy_name|/proxy_name> is C<fatal> so the typical
usage looks more like

    fatal $handler, @optional_arguments;

I<$handler> is expected to be a string (NOT a CodeRef!) that names a
user-defined subroutine.

The Proxy performs the following actions:

=over 4

=item B<1 - Capture the Environment>

Perl's error/status variables $ARG, $ERRNO, $CHILD_ERROR and $EVAL_ERROR
(also known as B<$_>, B<$!>, B<$?> and B<$@>, respectively) are all
captured as soon as possible to preserve their values for examination by
I<$handler>.

=item B<2 - Create a Carp::Proxy object>

The Proxy supplies settings for all the object's required attributes,
see L<ATTRIBUTES|/ATTRIBUTES>.  The Proxy also
forwards initializations for any attributes supplied by the user (arguments
to B<use()> or L<import()|/import>).

=item B<3 - Call begin_hook>

The L<begin_hook|/begin_hook> attribute, if it exists, is
called, passing the object as the only argument.

=item B<4 - Locate the Handler>

Locating the Handler is a complex process; see
L<HANDLER SEARCH|/HANDLER-SEARCH:>.  Briefly, the default behavior is to use
the first subroutine it finds from the following list of templates.  The
list is evaluated once for each package in the
L<handler_pkgs|/handler_pkgs> attribute.

    <package>::_cp_<handler_name>
    <package>::_<handler_name>
    <package>::<handler_name>

=item B<5 - Call Handler>

The Handler is called with the object as the first argument.  Any
arguments passed to the Proxy, beyond the handler-name, are propagated as
additional arguments to the Handler.

=item B<6 - Add Calling Context (Stacktrace)>

The method L<add_context()|/add_context> is invoked to generate a
Section with stacktrace content, as dictated by the
L<context|/context> attribute.

=item B<7 - Call end_hook>

The L<end_hook|/end_hook> attribute, if it exists, is called,
passing the object as the only argument.

=item B<8 - Perform Disposition>

The method L<perform_disposition()|/perform_disposition> is
invoked.  Disposition is controlled by the
L<disposition|/disposition> attribute; typically this means
passing the B<Carp::Proxy> object to B<die()>.

=back

If L<perform_disposition()|/perform_disposition> returns, rather
than throwing, then the returned value is propagated as the return value
of the Proxy.

=head1 ATTRIBUTES

All B<Carp::Proxy> object attributes have correspondingly named accessors.
When the accessors are invoked without arguments, they return the
attribute's value.  Mutable (Read-Write) attributes have accessors that can
be supplied with an argument to set the attribute's value.

Users generally do not create B<Carp::Proxy> objects directly; the Proxy
does that for them.  The object constructor, L<new()|/new>, requires
specification for several of the attributes like
L<eval_error|/eval_error>.  The Proxy supplies these required
attributes, but arguments to B<use()> or L<import()|/import> can override them.

All other attributes invoke a "builder" method to initialize the
attribute value if one is not provided.  Builder
methods are named with a prefix of B<'_build_'>.  You can change default
values for these attributes with arguments to B<use()> / L<import()|/import>,
or by providing custom builder functions in a sub-class.

=head2 arg

I<arg> holds the value of Perl's B<$ARG ($_)>, as harvested from the
invoking environment.  This can be handy if you are using
B<Try::Tiny>.

=over 4

=item Builder:    None; L<new()|/new> requires I<arg> specification.

=item Default:    N/A

=item Domain:     Any

=item Affects:    For user convenience; not used by B<Carp::Proxy>

=item Mutability: Read-Only

=back

=head2 as_yaml

The I<as_yaml> attribute is a flag that controls message rendering.
When False, message text is derived from the
L<sections|/sections> attribute; this is the normal mode of
operation.

When I<as_yaml> is True message text is a B<YAML::Dump()> of the
B<Carp::Proxy> object.  Serialization via YAML makes it possible to
propagate exceptions up from child processes.  See the section on
L<PROPAGATION|/PROPAGATION>.

=over 4

=item Builder:    _build_as_yaml()

=item Default:    0 (False)

=item Domain:     Boolean

=item Affects:    L<render_message()|/render_message>

=item Mutability: Read-Write

=back

=head2 banner_title

The Banner is the first part of the message; I<banner_title> contains the
first word(s) in the Banner.

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Fatal << handler name >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -----
       \
        +------ banner_title

=over 4

=item Builder:    _build_banner_title()

=item Default:    'Fatal'

=item Domain:     String

=item Affects:    L<banner()|/banner>

=item Mutability: Read-Write

=back

=head2 begin_hook

If I<begin_hook> contains a CodeRef then the Proxy will call the CodeRef
immediately after constructing the B<Carp::Proxy> object.  The object
is passed as the only argument.

A I<begin_hook> is a great way to always do some activity at the start of
every exception - before any Handler gets control.

=over 4

=item Builder:    _build_begin_hook()

=item Default:    undef

=item Domain:     undef or a CodeRef

=item Affects:    L<PROXY-INVOCATION|/PROXY-INVOCATION:>

=item Mutability: Read-Write

=back

=head2 body_indent

I<body_indent> influences the presentation of paragraphs created
by the Section creating methods L<filled()|/filled> and
L<fixed()|/fixed>.  Use I<body_indent> to determine the amount of
additional indentation, beyond L<header_indent|/header_indent>,
that is applied to Section paragraphs.

=over 4

=item Builder:    _build_body_indent()

=item Default:    2

=item Domain:     Non-negative integers

=item Affects:    L<filled_section()|/filled_section> and L<fixed_section()|/fixed_section>

=item Mutability: Read-Write

=back

=head2 child_error

I<child_error> holds the value of Perl's B<$CHILD_ERROR ($?)>, as harvested
from the invoking environment.

=over 4

=item Builder:    None; L<new()|/new> requires I<child_error> specification.

=item Default:    N/A

=item Domain:     Any

=item Affects:    L<decipher_child_error()|/decipher_child_error>

=item Mutability: Read-Only

=back

=head2 columns

The I<columns> attribute sets the line width target for the Banner and
for any filled Sections.  Values below about 30 are not practical.

=over 4

=item Builder:    _build_columns()

=item Default:    78

=item Domain:     Positive Integers

=item Affects:    L<banner()|/banner> and L<filled_section()|/filled_section>

=item Mutability: Read-Write

=back

=head2 context

The I<context> attribute controls the generation of a stacktrace Section.

=over 4

=item Builder:    _build_context()

=item Default:    'confess'

=item Domain:

=over 4

=item 'none' - No Section generated.

=item 'die' - Describe where Proxy was called.

=item 'croak' - Describe where Proxy's caller was called.

=item 'confess' - Stacktrace, starting with Proxy call.

=item 'internals' - Complete stacktrace with Carp::Proxy guts.

=item CodeRef - Do it yourself.

=back

=item Affects:    L<add_context()|/add_context>

=item Mutability: Read-Write

=back

=head2 disposition

The I<disposition> attribute controls how the exception is thrown.

=over 4

=item Builder:    _build_disposition()

=item Default:    'die'

=item Domain:

=over 4

=item 'return' - No exception thrown; Proxy returns.

=item 'warn' - Carp::Proxy object passed to Perl's B<warn()>.

=item 'die' - Carp::Proxy object passed to Perl's B<die()>.

=item CodeRef - Do it yourself.

=back

=item Affects:    L<perform_disposition()|/perform_disposition>

=item Mutability: Read-Write

=back

=head2 end_hook

If I<end_hook> contains a CodeRef then the Proxy will call the CodeRef
just before performing disposition.  The B<Carp::Proxy> object is
passed as the only argument.

The I<end_hook> is handy for things that you want all Handlers to do as
their last action.  An example might be writing to a logfile.

=over 4

=item Builder:    _build_end_hook()

=item Default:    undef

=item Domain:     undef or a CodeRef

=item Affects:    L<PROXY-INVOCATION|/PROXY-INVOCATION:>

=item Mutability: Read-Write

=back

=head2 eval_error

The I<eval_error> attribute holds the value of Perl's B<$EVAL_ERROR ($@)>,
as harvested from the invoking environment.

=over 4

=item Builder:    None; L<new()|/new> requires an I<eval_error> specification

=item Default:    N/A

=item Domain:     Any

=item Affects:    For user convenience; not used by B<Carp::Proxy>

=item Mutability: Read-Only

=back

=head2 exit_code

I<exit_code> is used to set the value harvested by the operating system
when a process dies.

=over 4

=item Builder:    _build_exit_code()

=item Default:    1

=item Domain:     Integers greater than Zero

=item Affects:    L<perform_disposition()|/perform_disposition>

=item Mutability: Read-Write

=back

=head2 fq_proxy_name

I<fq_proxy_name> is the fully-qualified proxy-name.  This is the Proxy's
name, complete with exported package qualifier.  This might be useful if
a Handler wants to know the parental Proxy.

=over 4

=item Builder:    None; L<new()|/new> requires I<fq_proxy_name> specification

=item Default:    N/A

=item Domain:     String

=item Affects:    L<add_context()|/add_context>

=item Mutability: Read-Write

=back

=head2 handler_name

The Proxy saves its first argument, the Handler, in I<handler_name>.

=over 4

=item Builder:    None; L<new()|/new> requires I<handler_name> specification

=item Default:    N/A

=item Domain:     String

=item Affects:    L<banner()|/banner>, L<HANDLER SEARCH|/HANDLER-SEARCH:>

=item Mutability: Read-Write

=back

=head2 handler_pkgs

The search for a Handler subroutine is performed in each of the packages
in the ArrayRef I<handler_pkgs>.  A copy of
L<proxy_package|/proxy_package> is automatically appended, by
the Proxy after object construction.

=over 4

=item Builder:    _build_handler_pkgs()

=item Default:    []

=item Domain:     ArrayRef

=item Affects:    L<HANDLER SEARCH|/HANDLER-SEARCH:>

=item Mutability: Read-Write

=back

=head2 handler_prefix

I<handler_prefix> affects how the search for a Handler is performed.
The list of templates that are tried during L<HANDLER SEARCH|/HANDLER-SEARCH:>
is based on I<handler_prefix>.

=over 4

=item Builder:    _build_handler_prefix()

=item Default:    undef

=item Domain:     undef or String

=item Affects:    L<HANDLER SEARCH|/HANDLER-SEARCH:>

=item Mutability: Read-Write

=back

=head2 header_indent

Section Headers are indented from the left margin by I<header_indent>
spaces.

=over 4

=item Builder:    _build_header_indent()

=item Default:    2

=item Domain:     Non-negative Integers

=item Affects:    L<header()|/header>, L<filled_section()|/filled_section> L<fixed_section()|/fixed_section>

=item Mutability: Read-Write

=back

=head2 maintainer

The L<contact_maintainer()|/contact_maintainer> method produces a
Section that urges the message recipient to contact the maintainer.  The
Section is created only if the I<maintainer> attribute is non-empty.  A
string containing an email address and a telephone number works well.

=over 4

=item Builder:    _build_maintainer()

=item Default:    ''

=item Domain:     String

=item Affects:    L<contact_maintainer()|/contact_maintainer>

=item Mutability: Read-Write

=back

=head2 numeric_errno

The I<numeric_errno> attribute contains the value of
Perl's B<$ERRNO ($!)>, as harvested from the invoking environment.  The
value is obtained by evaluating B<$ERRNO> in a numeric context.

=over 4

=item Builder:    None; L<new()|/new> requires I<numeric_errno> specification

=item Default:    N/A

=item Domain:     Any

=item Affects:    For user convenience; not used by B<Carp::Proxy>

=item Mutability: Read-Only

=back

=head2 pod_filename

The L<synopsis()|/synopsis> method searches for POD in
I<pod_filename>.

=over 4

=item Builder:    _build_pod_filename()

=item Default:    L<proxy_filename|/proxy_filename>.

=item Domain:     String

=item Affects:    L<synopsis()|/synopsis>

=item Mutability: Read-Write

=back

=head2 proxy_filename

The filename containing the code that requested construction of the Proxy,
either by B<use()> or L<import()|/import>.

=over 4

=item Builder:    None; L<new()|/new> requires I<proxy_filename> specification

=item Default:    N/A

=item Domain:     String

=item Affects:    L<pod_filename|/pod_filename>.

=item Mutability: Read-Only

=back

=head2 proxy_name

I<proxy_name> contains the name of the Proxy subroutine.

The default I<proxy_name> is B<'fatal'>.

The only time this attribute is used is when B<use()> or L<import()|/import>
are called without arguments.  Defining a B<_build_proxy_name()> in
a sub class allows you to change the default name.

=over 4

=item Builder:    _build_proxy_name(); L<new()|/new> requires I<proxy_name>

=item Default:    'fatal'

=item Domain:     String

=item Affects:    B<use()>, L<import()|/import>

=item Mutability: Read-Only

=back

=head2 proxy_package

The I<proxy_package> attribute is derived from the package that requested
construction of the Proxy, either by calling B<use()> or L<import()|/import>.

=over 4

=item Builder:    None; L<new()|/new> requires I<proxy_package> specification

=item Default:    Package of whatever subroutine called B<use()> or L<import()|/import>

=item Domain:     String

=item Affects:    L<handler_pkgs|/handler_pkgs>

=item Mutability: Read-Only

=back

=head2 section_title

The Section-creating methods L<filled()|/filled> and
L<fixed()|/fixed>, accept an optional, second argument to be used
as the title for the Section.  When this optional argument is not
supplied, I<section_title> is used instead.

=over 4

=item Builder:    _build_section_title()

=item Default:    'Description'

=item Domain:     Non-empty String

=item Affects:    L<header()|/header>, L<filled()|/filled>, L<fixed()|/fixed>

=item Mutability: Read-Write

=back

=head2 sections

The Section-creating methods L<filled()|/filled>,
L<fixed()|/fixed> and L<raw()|/raw> create Section
specifications. Section specifications accumulate in the ArrayRef
I<sections>.

=over 4

=item Builder:    _build_sections()

=item Default:    []

=item Domain:     ArrayRef of section-specifications

=item Affects:    L<render_message()|/render_message>

=item Mutability: Read-Write

=back

=head2 string_errno

I<string_errno> is a read-only attribute that contains the value of Perl's
B<$ERRNO ($!)>, harvested from the invoking environment.  The value is
obtained by evaluating B<$ERRNO> in a string context.

=over 4

=item Builder:    None; L<new()|/new> requires I<string_errno> specification

=item Default:    N/A

=item Domain:     String

=item Affects:    L<errno_section()|/errno_section>

=item Mutability: Read-Only

=back

=head2 tags

Passing arbitrary data to the catching environment can sometimes be
useful.  The I<tags> attribute is a HashRef for tag-value pairs of user
data.  The attribute is completely ignored by the Proxy and by
B<Carp::Proxy> methods.

=over 4

=item Builder:    _build_tags()

=item Default:    {}

=item Domain:     HashRef

=item Affects:    For user convenience; not used by B<Carp::Proxy>

=item Mutability: Read-Write

=back

=head1 METHODS

The documentation for each method starts off with a 'Usage' description.
A description will look something like this:

 Usage:
    <void> $cp->append_handler_package( $pkg <, $pkg2 ...>);

The word enclosed in angle-brackets, at the beginning, (Like
B<E<lt>voidE<gt>>) attempts to convey the return value.  Arguments in
angle-brackets are optional, with the ellipsis (B<...>) implying
repeatability.  B<$cp> is a B<Carp::Proxy> object.  B<$class>, if used as
the invoker, indicates a class method.

=head2 add_context

 Usage:
    <void> $cp->add_context();

B<add_context()> creates a Section that contains a stacktrace of where the
Proxy was invoked.  The L<context|/context> attribute controls
whether or not the Section is generated, as well as what kind of
stacktrace is produced.

B<add_context()> is called by the Proxy when the Handler returns.

Perl's B<caller()> is used to probe the callstack and report stackframes.
Stackframes are rendered on one line if the length would not exceed the
value of the L<columns|/columns> attribute.  Long lines are
folded at the filename portion of the stackframe and given
L<body_indent|/body_indent> extra spaces of indentation.

The L<context|/context> attribute may take on any of these
values:

=over 4

=item B<'none'>

The I<context> of C<'none'> is a request to forego stacktrace generation.
No Section is produced.

=item B<'die'>

The I<context> of C<'die'> adds a Section containing a single entry.  The
entry details the source location where the Proxy was invoked.  The effect
is intended to mimic Perl's behavior when B<die()> is passed a string
WITHOUT a trailing newline.

The title for the Section is C<'Exception'>.

    *** Exception ***
      fatal called from line 27 of /home/duane/bin/assim

=item B<'croak'>

The I<context> of C<'croak'> adds a Section that identifies the subroutine
that invoked the Proxy.  The effect is intended to mimic the behavior of
B<Carp::croak()>, which assigns blame to the caller.

The title for the Section is C<'Exception'>.

    *** Exception ***
      perform_query called from line 1172 of
        /opt/barkta/linux/v3.7/bin/ReadRecords

=item B<'confess'>

The I<context> setting of C<'confess'> creates a multi-line Section.
Lines in the Section correspond to stackframes from nearest to outermost,
much like the behavior of B<Carp::confess>.

C<'confess'> is the default I<context> for B<Carp::Proxy> objects.

The Section title is 'Stacktrace'.

=item B<'internals'>

The I<context> setting C<'internals'> is very similar to the setting
C<'confess'>.  Both produce full stacktraces, but C<'confess'> omits
stackframes that originate on behalf of the Proxy.  You normally do
not want to see B<Carp::Proxy> stackframes, although they might be helpful
in debugging a sub-class. C<'internals'> gives you everything.

The Section title is 'Stacktrace'.

=item B<CodeRef>

By providing a CodeRef users can completely control context reporting.

The Proxy will make a callback to I<CodeRef> immediately after the Handler
returns.  The B<Carp::Proxy> object will be passed as the only argument.
The CodeRef should create a Section using the L<filled()|/filled>,
L<fixed()|/fixed> or L<raw()|/raw> methods.

The B<Carp> module from the Perl standard library provides some complex
functionality for ignoring stackframes that you may find useful.

=back

=head2 append_handler_package

 Usage:
    <void> $cp->append_handler_package( $pkg <, $pkg2 ...>);

The attribute L<handler_pkgs|/handler_pkgs> is an ArrayRef.
B<append_handler_package()> is sugar to make adding packages to the end of
L<handler_pkgs|/handler_pkgs> easier.

=head2 append_section

 Usage:
    <void> $cp->append_section( $array_ref <, $array_ref2...>);

The L<sections|/sections> attribute is an ArrayRef containing
child ArrayRefs, one for each Section (like filled(), fixed() etc.).
B<append_section()> is sugar to make adding a Section request to the
L<sections|/sections> attribute, easier.  Section requests are
added to the end of L<sections|/sections> (appended).

=head2 banner

 Usage:
    <String> $cp->banner();

B<banner()> produces the multi-line introduction to a diagnostic message.
The Banner is intended to stand out visually so it fills up the horizontal
space from left to right margins.  The value of
L<columns|/columns> dictates the amount of fill needed.  The
Banner looks something like this:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    <banner_title> << <cleansed_handler> >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In the above template, I<banner_title> is taken directly from the
L<banner_title|/banner_title> attribute.  I<cleansed_handler> is
generated by invoking
L<identifier_presentation()|/identifier_presentation> on the
L<handler_name|/handler_name> attribute.

=head2 call

 Usage:
    <void> $cp->call( $handler, @optional_arguments );

The task of Handlers is to create Sections.  Handlers can call other
Handlers to compose common Sections.

Most Handlers know how to locate their peers because they reside in the
same package and have the same prefix conventions.  B<call()> can
certainly be used to invoke peers, although it might seem like overkill.

B<call()> is useful when Handlers reside in a hierarchy of packages and
you need a full search.  B<call()> is also the only way to invoke
L<BUILTIN HANDLERS|/BUILTIN-HANDLERS:>.

    $cp->call( '*assertion_failure*', $description, \%status_vars );

B<call()> runs the algorithm described in L<HANDLER SEARCH|/HANDLER-SEARCH:>.

=head2 contact_maintainer

 Usage:
    <void> $cp->contact_maintainer();

If the L<maintainer|/maintainer> attribute is non-empty then a
Section containing the L<maintainer|/maintainer> string is
created.  No Section is created if L<maintainer|/maintainer> is
empty.

This works well if L<maintainer|/maintainer> contains contact
info.

    *** Please contact the maintainer ***
      Your Name  your.name@help.org   (123)456-7890

=head2 decipher_child_error

 Usage:
    <void> $cp->decipher_child_error();
    -or-
    <void> $cp->decipher_child_error( $child_error );

Perl's B<$CHILD_ERROR> (B<$?>) encodes several bits of information about
how a child process terminates, see the B<perlvar> documentation on
B<$CHILD_ERROR> for details.  B<decipher_child_error()> unpacks the
various bits of information in B<$CHILD_ERROR> and converts them into a
L<filled()|/filled> Section.  Examples:

    *** Process Succeeded ***
      The child process completed normally (exit code 0).

    *** Process returns failing status ***
      The child process terminated with an exit code of 14.

    *** Process terminated by signal ***
      The child process was terminated by SIGSEGV (signal 11).

If a I<$child_error> argument is provided then the argument value is
deciphered, otherwise the value held in the L<child_error|/child_error>
attribute is used.

=head2 directory

 Usage:
    <void> $cp->directory( $dir <, $title >);

The B<directory()> method creates a L<fixed()|/fixed> Section.  The
optional I<$title>, if supplied, forms the title for the Section,
otherwise C<'Directory'> is used as the title.

Output from B<Cwd::abs_path()> is used to form the body of the Section.

=head2 errno_section

 Usage:
    <void> $cp->errno_section( <$title> );

A filled Section is created using the contents of the
L<string_errno|/string_errno> attribute.  If I<$title> is
not provided then 'System Diagnostic' is used as the Header title.

No Section is created if the L<string_errno|/string_errno>
attribute is empty.

=head2 filename

 Usage:
    <void> $cp->filename( $file <, $title >);

The B<filename()> method creates a L<fixed()|/fixed> Section.  The
optional I<$title>, if supplied, forms the title for the Section,
otherwise C<'Filename'> is used as the title.

Output from B<Cwd::abs_path()> is used to form the body of the Section.

=head2 filled

 Usage:
    <void> $cp->filled( $content <, $title >);

B<filled()> creates a Section.  The Section is introduced with a
L<header()|/header> containing I<$title>.  The body of the Section is
produced by reformatting I<$content> into paragraphs of length-limited
lines.

If I<$title> is not supplied, or if it is undef, then the
L<section_title|/section_title> attribute is used in its place.  If
I<$title> is an empty string then no Header is produced.  This makes it
easy to chain together Fixed and Filled Sections under the same Header.

Any spaces at the beginning of each paragraph in I<$content> sets the
relative indentation for the whole paragraph.  Each paragraph may have
different indentations.

Paragraphs are reformatted by splitting them into words, on whitespace, then
building up new lines.  Each line starts with spaces corresponding to the
sum of L<header_indent|/header_indent>, L<body_indent|/body_indent> and any
paragraph-specific indentation.  Lines are then filled with words to achieve
a target line width.  The target width is given by the L<columns|/columns>
attribute.

In actuality, all the B<filled()> method does is to add a request for a
"filled_section" onto the end of the B<sections> list.  The actual
processing is performed by L<filled_section()|/filled_section> when
L<render_message()|/render_message> traverses the B<sections> list.
What this means is that the settings for attributes like
L<section_title|/section_title>, L<columns|/columns>,
L<header_indent|/header_indent> and
L<body_indent|/body_indent> only come into play when
L<render_message()|/render_message> is run.

See L<filled_section()|/filled_section> for details.

=head2 filled_section

 Usage:
    <String> $cp->filled_section( $content, $title );

B<filled_section()> is not usually invoked directly by users.
L<render_message()|/render_message> invokes B<filled_section()> as it
traverses the list held in the L<sections|/sections> attribute.

I<$content> is expected to be a string.  If I<$content> is an empty string
then no Section is produced - an empty string is returned.

I<$title> is converted into a section-title using L<header()|/header>.

I<$content> is split into paragraphs wherever there are two or more
consecutive newlines, more specifically using this regex:

    /(?: \r? \n ){2,}/x

Each paragraph is examined for leading whitespace.  This leading whitespace
is processed by converting tabs into spaces on eight-column boundarys.  The
converted whitespace forms the supplemental indentation for the paragraph.

New paragraphs are formed a line at a time by starting with an indentation
amount corresponding to the sum of L<header_indent|/header_indent>,
L<body_indent|/body_indent> and any supplemental indentation.  Words from
the old paragraph are added to the line so long as the line length does not
exceed L<columns|/columns>.  At least one word is always added, even if
L<columns|/columns> is exceeded.

Any trailing whitespace is removed.  Output paragraphs are joined with a
blank line.  The returned string is the concatenation of the section title,
the paragraphs and a trailing blank line.

Override B<filled_section()> in a sub-class, rather than
L<filled()|/filled>, if you want different filling behavior.

=head2 fixed

 Usage:
    <void> $cp->fixed( $content <, $title >);

B<fixed()> creates a Section.  The Section is introduced with a
L<header()|/header> containing I<$title>.  The body of the Section is formed
by retaining the formatting already present in I<$content>.

If I<$title> is not supplied, or if it is undef, then the
L<section_title|/section_title> attribute is used in its place.  If
I<$title> is an empty string then no Header is included.  This makes it easy
to chain together Fixed and Filled Sections under the same Header.

Each line in I<$content> is indented by a constant amount corresponding to
the L<header_indent|/header_indent> plus the L<body_indent|/body_indent>.
Tabs in I<$content> are folded into spaces to preserve column alignment
before the indentation is prepended.  Trailing whitespace on each line is
replaced with an appropriate line terminator for the platform. I<$content>
is otherwise unmolested.  Almost WYSIWYG.

In actuality, all the B<fixed()> method does is to add a request for a
"fixed_section" onto the end of the B<sections> list.  The actual processing
is performed by the L<fixed_section()|/fixed_section> method when the
L<render_message()|/render_message> method traverses the B<sections> list.
What this means is that the settings for attributes like
L<section_title|/section_title>, L<header_indent|/header_indent> and
L<body_indent|/body_indent> only matter at the time
L<render_message()|/render_message> is run.

See L<fixed_section()|/fixed_section> for details.

=head2 fixed_section

 Usage:
    <String> $cp->fixed_section( $content, $title );

B<fixed_section()> is not usually invoked directly by users.
L<render_message()|/render_message> invokes B<fixed_section()> as
it traverses the list in the L<sections|/sections> attribute.

I<$content> is expected to be a string.  If I<$content> is the empty
string then no Section is generated and an empty string is returned.

I<$title> is converted into a Section title string using
L<header()|/header>.

I<$content> is split into lines on newline ("\n") characters for
processing.  Trailing whitespace is removed.  Embedded tabs are converted
to the equivalent number of spaces assuming eight character boundarys.
Indentation corresponding to the sum of
L<header_indent|/header_indent> and
L<body_indent|/body_indent> is added to the beginning of each
line.  Lines are joined with platform-appropriate line termination.

Trailing whitespace is removed, the section-title is prepended and a
single blank line is added to the end.

=head2 header

 Usage:
    <String> $cp->header( $title );

B<header()> produces an introductory line for a Section of paragraphs.
The line is indented from the left margin by
L<header_indent|/header_indent> spaces.  The line is formed
using the following template:

    <indent>*** <$title> ***

The intent is to provide an introductory heading for Section paragraphs.

    *** Description ***
      The database server is refusing connections.

If I<$title> is undef then the L<section_title|/section_title>
attribute is used in its place.  Passing an empty string (C<''>) for
I<title> causes B<header()> to omit Header generation.  In this case an
empty string is returned.

B<header()> is called by the Section creating methods
L<filled_section()|/filled_section> and
L<fixed_section()|/fixed_section>.

Subclass B<Carp::Proxy> and override B<header()> for a different look.

=head2 identifier_presentation

 Usage:
    <String> $class->identifier_presentation( $name );

The Banner reads better when words in the
L<handler_name|/handler_name> are separated by spaces rather
than underscores (C<_>).  Likewise with camelCasedIdentifiers.

Underscores are replaced by single spaces everywhere they occur.  Spaces
are inserted everywhere character-case changes from lower to upper, and
upper-case characters are folded to lower-case.  The following are example
conversions:

    'no_user_credentials'  => 'no user credentials'
    'nonexistentRecord'    => 'nonexistent record'

Sub-class B<Carp::Proxy> and override B<identifier_presentation()> if
you want a different convention.

=head2 import

 Usage:
    <void> $class->import( <%attrs_by_proxy>);

B<import()> accepts specifications for Proxy construction.  Specifications
take the form of a proxyname and a hashref of attribute initializations.

    proxyname1 => {
                   attributeA => initial_valueA,
                   attributeB => initial_valueB,
                   ...
                  }

Any number of proxyname, hashref pairs may be specified; a proxy subroutine
will be constructed for each pair.

If there is only one argument it is taken to be a proxyname introducing an
empty hashref.  If there are no arguments then it is assumed that the
builder-specified default for the L<proxy_name|/proxy_name> attribute
(C<'fatal'>), should be used for the proxyname and an empty hashref used for
the attribute initializations.

B<import()> probes the callstack to determine the package and filename of
the user code that called B<import()>.  B<import()> uses these values to create
a hash containing the attributes L<proxy_filename|/proxy_filename>,
L<proxy_name|/proxy_name> L<proxy_package|/proxy_package> and
L<fq_proxy_name|/fq_proxy_name>.  Any supplied attributes are added to the
hash.  The builtin handler L<*configuration*|/configuration> returns a
reference to this hash.

=head2 list_handler_packages

 Usage:
    <list> $cp->list_handler_packages();

B<list_handler_packages()> is sugar that dereferences the
L<handler_pkgs|/handler_pkgs> attribute (an ArrayRef) and
returns the contents.

=head2 list_sections

 Usage:
    <list> $cp->list_sections();

The L<sections|/sections> attribute is an ArrayRef.
B<list_sections()> is sugar to return all the elements of
L<sections|/sections>.

=head2 new

 Usage:
    <Carp::Proxy object> $class->new
        ( arg            => harvested $_,
          eval_error     => harvested $@,
          fq_proxy_name  => 'package::subname',
          handler_name   => 'name of handler',
          numeric_errno  => harvested 0 + $!,
          proxy_filename => 'filename',
          proxy_name     => 'subname',
          proxy_package  => 'package',
          string_errno   => harvested '' . $!,
          < attribute    => value ...>
        );

I<new()> is normally called by the Proxy, so this documentation is only
useful if you are using the object for your own purposes.  There are a large
number of required attribute-value pairs.  Specification for any additional
attributes is supported.  Builder methods are invoked for all unspecified
attributes.

There is some inconsistency around the L<proxy_name|/proxy_name> attribute.
The L<proxy_name|/proxy_name> is required by I<new()> even though it has a
builder method.  The builder is for use by L<import()|/import>, which
invokes it if needed, and passes the result to new().

=head2 perform_disposition

 Usage:
    <Scalar> $cp->perform_disposition();

The L<disposition|/disposition> attribute determines the final
actions of the Proxy, which are carried out by B<perform_disposition()>.
Valid settings for L<disposition|/disposition> are:

=over 4

=item B<'warn'>

A I<disposition> of C<'warn'> causes B<perform_disposition()> to do this:

    warn $cp;
    return ();

=item B<'die'>

A I<disposition> of C<'die'> causes B<perform_disposition()> to do this:

    $ERRNO = $cp->exit_code;
    die $cp;

See Perl's B<die()> for an explanation of propagating $ERRNO into the exit
code for the process.

C<'die'> is the default I<disposition>.

=item B<'return'>

The I<disposition> of C<'return'> is unusual; it signifies a desire to
abort the whole death-by-proxy process.  B<perform_disposition> does this:

    return $cp;

=item B<CodeRef>

The user can take control of disposition by supplying a CodeRef for
I<disposition>.  In this case, the behavior of B<perform_disposition()>
is:

    return $cp->disposition->( $cp );

=back

=head2 prepend_handler_package

 Usage:
    <void> $cp->prepend_handler_package( $pkg <, $pkg2...>);

The attribute L<handler_pkgs|/handler_pkgs> is an ArrayRef.
B<prepend_handler_package()> is sugar to make adding packages to the front
of L<handler_pkgs|/handler_pkgs> easier.

=head2 prepend_section

 Usage:
    <void> $cp->prepend_section( $array_ref <, $array_ref2...>);

The L<sections|/sections> attribute is an ArrayRef containing
child ArrayRefs, one for each Section (like filled(), fixed() etc.).
B<prepend_section()> is sugar to make adding a Section request to the
L<sections|/sections> attribute, easier.  Section requests are
added to the front of L<sections|/sections> (prepended).

=head2 raw

 Usage:
    <void> $cp->raw( $content );

B<raw()> provides an alternative to L<fixed()|/fixed> and
L<filled()|/filled> for composing diagnostic Sections.

In effect, B<raw()> creates a Section containing only B<$content>.
You are completely responsible for the final appearance of the Section;
there is no Header, no trailing blank line, no indentation and no
platform appropriate line termination.

In actuality, all the B<raw()> method does is to add a request for a raw
Section onto the B<sections> list; the actual processing is performed by
the L<raw_section()|/raw_section> method when the
L<render_message()|/render_message> traverses B<sections>.

See L<raw_section()|/raw_section> for details.

=head2 raw_section

 Usage:
    <String> $cp->raw_section( $content );

B<raw_section()> is not usually invoked directly by users.
L<render_message()|/render_message> invokes B<raw_section()> as it
traverses the list in the L<sections|/sections> attribute.

B<raw_section()> does nothing; the returned string is simply a copy of
I<$content>.

=head2 render_message

 Usage:
    <String> $cp->render_message();

The behavior of B<render_message()> is dependent on the setting of the
attribute L<as_yaml|/as_yaml>.  If L<as_yaml|/as_yaml> is False, which is
the default, then B<render_message()> walks the list of
section-specifications stored in the L<sections|/sections> attribute,
executing each one in turn.  The return value is formed by concatenating
each of the results.

The L<sections|/sections> attribute, an ArrayRef, is expected to contain any
number of ArrayRef elements.  Each child ArrayRef must have at least one
element: the name of a method to be invoked.  Any remaining elements are
passed to the invoked method as arguments.  For example, a
L<sections|/sections> specification that looks like this:

    [
     [ 'filled_section', 'content1', 'title1' ],
     [ 'filled_section', 'content2', 'title2' ],
    ]

Results in the execution of something like this:

    my $buffer = $cp->banner();

    $buffer .= $cp->filled_section( 'content1', 'title1' );
    $buffer .= $cp->filled_section( 'content2', 'title2' );

    return $buffer;

The L<sections|/sections> list is unchanged by the traversal, so
B<render_message()> may be invoked repeatedly.  Settings for attributes like
L<banner_title|/banner_title>, L<columns|/columns>,
L<section_title|/section_title>, L<header_indent|/header_indent> and
L<body_indent|/body_indent> can be changed between invocations to vary the
message format.

Changing attributes like L<context|/context>, which are
referenced during the generation of Section specifications, have no effect.

If L<as_yaml|/as_yaml> is True then we return a string that
is a YAML dump of the B<Carp::Proxy> object, something like this:

    return YAML::XS::Dump( $cp );

The intent here is to use YAML to serialize all aspects of the
B<Carp::Proxy> object.  Assuming that we have a
L<disposition|/disposition> setting of B<die>, our
serialized object will be written out to STDERR, where it can be captured
by a parent process and reconstituted.  The reconstituted object can
be examined, or augmented with parental context and rethrown.

=head2 synopsis

 Usage:
    <void> $cp->synopsis( %optional_supplements );

The B<synopsis()> method employs B<Pod::Usage::pod2usage()> to create a
Section from the user's POD.  User POD is located by searching in the
L<pod_filename|/pod_filename> attribute.

The call to B<pod2usage()> is passed a HashRef with the following options:

    -input   => $cp->pod_filename,
    -output  => <filehandle>,
    -exitval => 'NOEXIT',
    -verbose => 0,

This set of options causes B<pod2usage()> to format the B<SYNOPSIS>
portion of the user's POD.  Any key-value pairs in
B<%optional_supplements> are appended to the contents of the HashRef,
allowing you to override or supplement these defaults.

=head3 Example

Internally, B<Carp::Proxy> uses B<synopsis()> to extract sections from this
POD document when composing diagnostics.  If, for instance, you supply a
negative value as the setting for L<body_indent|/body_indent> you get an
exception.  The text of the exception is generated using something like
this:

    $cp->synopsis( -verbose  => 99,
                   -sections => ["ATTRIBUTES/body_indent"],
                 );

The resulting diagnostic looks something like this:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Oops << negative body indentation >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      *** Description ***
        The requested setting of '-1' for the 'body_indent'
        attribute is not allowed.
 
      *** Synopsis ***
          body_indent:
            *body_indent* influences the presentation of paragraphs
            created by the Section creating methods filled() and
            fixed(). Use *body_indent* to determine the amount of
            additional indentation, beyond header_indent, that is
            applied to Section paragraphs.
 
            Builder: _build_body_indent()
            Default: 2
            Domain: Non-negative integers
            Affects: filled_section() and fixed_section()
            Mutability: Read-Write
 
      *** Stacktrace ***
        ...

See L<'perldoc Pod::Usage'|Pod::Usage> and
L<'perldoc Pod::Select'|Pod::Select> for details about using B<-verbose>
and B<-sections>.

=head2 usage

 Usage:
    <void> $cp->usage();

B<usage()> examines the callstack, to find the invoker - the subroutine
that invoked the Proxy.  A pass through the
L<HANDLER SEARCH|/HANDLER-SEARCH:> algorithm is made to see if it can find
a subroutine with this name:

    usage_<invoker>

In the default configuration this means that these three subroutine
names are tested for existence:

    <package>::_cp_usage_<invoker>
    <package>::_usage_<invoker>
    <package>::usage_<invoker>

Just like the search for a Handler, the settings for
L<handler_prefix|/handler_prefix> and
L<handler_pkgs|/handler_pkgs> influence the where and what of
the search for a usage subroutine.

If none of the attempts finds an existing subroutine then the next entry in
the callstack (i.e. the invoker of the invoker) is tried.  The progression
up the callstack continues until there are no more stackframes.  At this
point the algorithm gives up and throws a "no usage documentation" exception.

The search sounds complex, but the intent is simple: public subroutines
and methods can call utilities, say to validate incoming arguments, and
these utilities can call Proxys to throw exceptions.  When the Handler
invokes B<usage()> we eventually find a usage message associated with the
public subroutine.

    #----- We want this to be called for help with 'my_func()'
    sub _usage_my_func {
        my( $cp ) = @_;

        $cp->fixed( 'Usage: <num> my_func( val );', 'Usage' );
        $cp->filled( 'my_func() returns blah blah blah.', '' );
    }

    sub my_func {
        my( $val ) = @_;

        fatal 'missing_argument', 'val'
            if not defined $val;
        ...
    }

    #----- Reusable by anyone that defines their own _usage_
    sub _cp_missing_argument {
        my( $cp, $name ) = @_;

        $cp->filled("The argument '$name' is missing, or undef.");
        $cp->usage;
    }

Other subroutines, besides my_func(), can throw fatal exceptions with the
'missing_argument' Handler.  The diagnostic will be customized
appropriately for each one.

The invoker-upward aspect of the search means that B<my_func()>, instead
of calling B<fatal()> directly, could have called an arg-checking utility,
which called another utility etc., which finally called B<fatal()>.  The
search would have eventually located B<_usage_my_func()>.

=head1 HANDLER SEARCH

A Proxy invocation contains, as its first argument, a string that will
become the L<handler_name|/handler_name> attribute.  The string
C<'no_such_author'> is used to establish
L<handler_name|/handler_name> in this example:

    fatal 'no_such_author', $who;

The Proxy calls the Handler to build up the diagnostic message, but first
it must locate the requested subroutine.

The search for a Handler subroutine is made in the packages found in
L<handler_pkgs|/handler_pkgs>.  Users can specify a list of
packages to search by supplying the tagged list to B<use()> or
L<import()|/import>.

    package main;
    use Carp::Proxy fatal => { handler_pkgs => [qw( Support Common )]};

You can also sub-class B<Carp::Proxy> and override
B<_build_handler_pkgs()> to return an ArrayRef of the desired packages.

The Proxy always appends a copy of
L<proxy_package|/proxy_package> to
L<handler_pkgs|/handler_pkgs> after object construction.
L<proxy_package|/proxy_package> is the package that issued the
B<use()>, or made the call to L<import()|/import>.  In the above example
L<handler_pkgs|/handler_pkgs> becomes:

    [qw( Support Common main )]

The subroutine that is the target of the search is influenced by the
setting of L<handler_prefix|/handler_prefix>.  When the
L<handler_prefix|/handler_prefix> attribute is undef, the Proxy
builds three templates from L<handler_name|/handler_name>.  The
first subroutine that exists is used as the Handler.

    <package>::_cp_<handler_name>
    <package>::_<handler_name>
    <package>::<handler_name>

If L<handler_prefix|/handler_prefix> is not undef then only one
template is tried:

    <package>::<handler_prefix><handler_name>

If a Handler subroutine is not found by the template search then a check
is made to see if L<handler_name|/handler_name> matches one of
the B<Carp::Proxy> builtin Handlers.  The builtin Handlers are surrounded
by C<'*'> characters since those are guaranteed not to collide with user
Handlers.

    *assertion_failure*
    *internal_error*
    *configuration*

See L<BUILTIN HANDLERS|/BUILTIN-HANDLERS:> for a description of their
functionality.

Finally, if a suitable Handler is not found by any of the above searches
the Proxy concludes that you forgot to define a Handler.  In response, the
Proxy attempts to shame you into compliance by throwing an exception of
its own:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Oops << embarrassed developers >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      *** Description ***
        There was an error.  The developers caught the error and
        attempted to pass diagnosis off to a handler.  Unfortunately
        they forgot to define the handler.  Now there are two
        errors.  You should complain!

      *** Please contact the maintainer ***
        your.name@support.org   555-1212

      *** Missing Handler ***
        handler_name:   no_credentials
        handler_pkgs:   main
        handler_prefix: (undef)

      *** Stacktrace ***
        fatal called from line 443 of /usr/local/bin/hibs
	validate_user called from line 510 of /usr/local/bin/hibs
	cmdline called from line 216 of /usr/local/bin/hibs
	main called from line 17 of /usr/local/bin/hibs

=head1 BUILTIN HANDLERS

These are handler subroutines that come with B<Carp::Proxy>.

=head2 internal_error

 Usage:
    <void> fatal '*internal_error*', @strings;

The C<'*internal_error*'> Handler can be used to promote warnings to
errors or to turn miscellaneous B<die()> exceptions to full B<Carp::Proxy>
exceptions.  The typical use is to trap B<$SIG{__DIE__}> or
B<$SIG{__WARN__}>.

    use English;
 
    $SIG{__DIE__} = sub{
 
        fatal '*internal_error*', @_
            if not $EXCEPTIONS_BEING_CAUGHT;
    };

A Filled Section is generated from the string interpolation of
I<@strings>.  In the above example, the argument is the message that was
passed to B<die()>, like "Illegal division by zero".  A
L<contact_maintainer()|/contact_maintainer> Section is also added.

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Fatal: << internal error >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      *** Description ***
        Illegal division by zero at ./combine_decks line 27.

      *** Please contact the maintainer ***
        your.name@support.org   555-1212

      *** Stacktrace ***
        ...

=head2 assertion_failure

 Usage:
    <void> fatal '*assertion_failure*', $description <, $hashref>;

If a failing assertion is indicative of a programmer fault then the
primary audience for a diagnostic message will be a maintainer rather than
an end user.  Maintainers are most often helped by knowledge of the
surrounding state.  The builtin Handler B<*assertion_failure*> attempts to
be a generic Handler, useful for transmitting state to maintainers.

Using B<*assertion_failure*> frees the programmer from having to write a
Handler.  The tradeoff is that some ability to customize the diagnostic is
lost and the invocation syntax is more cluttered.  The tradeoff can be
reasonable for events that are rarely triggered, especially if it
encourages programmers to add more assertions.

B<'*assertion_failure*'> produces a Filled Section with some boilerplate
containing the supplied I<$description>.

Also included is a Fixed Section which contains a YAML dump of
I<$hashref>.  This works best when the HashRef keys act as informational
names (tag=>value pairs) to convey state.  YAML is nice here because it
does a great job of serializing complex data structures.

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Fatal: << assertion failure >>
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      *** Description ***
        An assertion has failed.  This indicates that the internal
        state of the program is corrupt.

        <$description>

      *** Please contact the maintainer ***
        your.name@support.org   555-1212

      *** Salient State (YAML) ***
        ---
        failure: 'unmatched case'
        index: 27
        selection: 'brunch'

      *** Stacktrace ***
        ...

=head2 configuration

 Usage:
    <HashRef> fatal '*configuration*';

The C<'*configuration*'> Handler is unconventional in that no exception is
thrown.  Instead, a reference to an internal hash is returned to the
calling environment.  Any changes to the referenced hash affect all future
Proxy invocations.

Proxy configuration is established when a Proxy is created - either during
B<use()> or L<import()|/import>.  Configuration consists of attribute
=E<gt> parameter pairs that are supplied by the user.

    use Carp::Proxy ( warning => { banner_title => 'Warning',
                                   disposition  => 'warn'      });

In the above snippet, L<banner_title|/banner_title> and
L<disposition|/disposition>, are internally held in a
closure-based hash that persists across all invocations of the Proxy.  The
B<*configuration*> Handler causes the Proxy to return a reference to this
internal hash.

Here is an example of wanting to change Proxy behavior after Proxy
creation:

    #----- fatal() does NOT throw an exception here...
    my $config = fatal '*configuration*';
 
    $config->{ disposition } = \&GUI::as_dialog;

As alluded to above, we want our GUI program to use conventional STDERR
based messages during initialization, but once the GUI is up we want
future messages to go to a dialog widget.

=head1 PROPAGATION

The I<as_yaml> attribute controls stringification of the Proxy object.
In its normal state of false (0), I<as_yaml> produces the formatted
error message.  When true (1), I<as_yaml> instead produces a YAML Dump()
of the proxy object.

Newer versions of YAML do not bless reconstituted objects as a security
precaution, so if you want to propagate errors up from child processes
you will need to specifically allow it.

    # 'cmd' here throws a fatal() with as_yaml set to 1
    $output = qx{ cmd 2>&1 1>/dev/null };
 
    if ( $CHILD_ERROR ) {
 
        my $kids_proxy;
        {
            local $YAML::XS::LoadBlessed = 1;
            $kids_proxy = YAML::XS::Load( $output );
        }
        do_something( $kids_proxy )
    }


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-carp-proxy at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-Proxy>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 DEPENDENCIES

Core dependencies (come with Perl)

 Config
 Cwd
 English
 overload
 Pod::Usage

External dependencies (install from CPAN)

 Moose
 Readonly
 Sub::Name
 YAML::XS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Carp::Proxy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Proxy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Carp-Proxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Proxy>

=item * Search CPAN

L<http://search.cpan.org/dist/Carp-Proxy/>

=back


=head1 SEE ALSO

=over 4

=item perldoc L<perlvar>

The section on $CHILD_ERROR describes information packing when a child
process terminates.  This is used by
L<decipher_child_error()|/decipher_child_error>.

=item perldoc -f die

The documentation on Perl's B<die()> details how the exit code for a process
depends on B<$ERRNO> and B<$CHILD_ERROR>.

=item perldoc L<Pod::Usage>

The L<synopsis()|/synopsis> method calls B<pod2usage()> to format
the B<SYNOPSIS> section from user POD.

=item perldoc L<YAML::XS>

The L<as_yaml|/as_yaml> attribute produces a YAML Dump of the
B<Carp::Proxy> object so that it can be reconstituted later.

The L<*assertion_failure*|/assertion_failure> builtin
Handler produces a Section containing YAML Dump of a user HashRef.

=item perldoc L<Carp>

The 'croak' and 'confess' concepts were originated by B<Carp>.  If you are
making a Do-it-yourself CodeRef for L<context|/context> then
B<Carp>'s B<longmess()> or B<longmess_heavy()> may prove useful.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2020 Paul Liebert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
