use strict;
use warnings;
package Data::Beacon;
#ABSTRACT: BEACON format validating parser and serializer
our $VERSION = '0.3.1'; #VERSION

use 5.008;
use Time::Piece;
use Scalar::Util qw(blessed);
use URI::Escape;
use Carp;

use base 'Exporter';
our @EXPORT = qw(plainbeaconlink beacon);


sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->_initparams( @_ );
    $self->_startparsing;
    return $self;
}


sub meta { # TODO: document meta fields
    my $self = shift;
    return %{$self->{meta}} unless @_;

    if (@_ == 1) {
        my $key = uc(shift @_);
        $key =~ s/^\s+|\s+$//g;
        return $self->{meta}->{$key};
    }

    croak('Wrong number of arguments in SeeAlso::Beacon->meta') if @_ % 2;

    my %list = (@_);
    foreach my $key (keys %list) {
        croak('invalid meta name: "'.$key.'"') 
            unless $key =~ /^\s*([a-zA-Z_-]+)\s*$/; 
        my $value = $list{$key};
        $key = uc($1);
        if ( defined $value ) {
            $value =~ s/^\s+|\s+$|\n//g;
        } else {
            $value = '';
        }
        if ($value eq '') { # empty field: unset
            croak 'You cannot unset meta field #FORMAT' if $key eq 'FORMAT';
            delete $self->{meta}->{$key};
        } else { # check format of known meta fields
            if ($key eq 'TARGET') {
                $value =~ s/{id}/{ID}/g;
                # TODO: document that {ID} in target is optional (will be appended)
                $value .= '{ID}' unless $value =~ /{ID}}/; 
                my $uri = $value; 
                $uri =~ s/{ID}//g;
                croak 'Invalid #TARGET field: must be an URI pattern'
                    unless _is_uri($uri);
            } elsif ($key eq 'FEED') {
                croak 'FEED meta value must be a HTTP/HTTPS URL' 
                    unless $value =~ 
  /^http(s)?:\/\/[a-z0-9-]+(.[a-z0-9-]+)*(:[0-9]+)?(\/[^#|]*)?(\?[^#|]*)?$/i;
            } elsif ($key eq 'PREFIX') {
                croak 'PREFIX meta value must be a URI' 
                    unless _is_uri($value);
            } elsif ( $key =~ /^(REVISIT|TIMESTAMP)$/) {
                if ($value =~ /^[0-9]+$/) { # seconds since epoch
                    $value = gmtime($value)->datetime() . 'Z'; 
                    # Note that this conversion does not trigger an error
                    # or warning, but may be dropped in a future version
                } else {
                    # ISO 8601 combined date and time in UTC
                    $value =~ s/Z$//;
                    croak $key . ' meta value must be of form YYYY-MM-DDTHH:MM:SSZ'
                        unless $value = Time::Piece->strptime( 
                            $value, '%Y-%m-%dT%T' );
                    $value = $value->datetime();
                }
            } elsif ( $key eq 'FORMAT' ) {
                croak 'Invalid FORMAT, must be BEACON or end with -BEACON'
                    unless $value =~ /^([A-Z]+-)?BEACON$/;
            } elsif ( $key eq 'EXAMPLES' ) {
                my @examples = map { s/^\s+|\s+$//g; $_ } split '\|', $value;
                $self->{examples} = [ grep { $_ ne '' } @examples ];
                %{$self->{expected_examples}} = 
                    map { $_ => 1 } @{$self->{examples}};
                $value = join '|', @{$self->{examples}};
                if ($value eq '') { # yet another edge case: "EXAMPLES: |" etc.
                    delete $self->{meta}->{EXAMPLES};
                    $self->{expected_examples} = undef;
                    next;
                }
                # Note that examples are not checked for validity,
                # because PREFIX may not be set yet.
            }
            $self->{meta}->{$key} = $value;
        }
    }
}


sub count {
    my $count = $_[0]->meta('COUNT');
    return defined $count ? $count : 0;
}


sub line {
    return $_[0]->{line};
}


sub lasterror {
    return wantarray ? @{$_[0]->{lasterror}} : $_[0]->{lasterror}->[0];  
}


sub errors {
    return $_[0]->{errors};
}


sub metafields {
    my $self = shift;
    my %meta = $self->meta();
    my %fields = %meta;

    # determine default order
    my @order = (qw(FORMAT PREFIX TARGET MESSAGE RELATION ANNOTATION),
        qw(DESCRIPTION CREATOR CONTACT HOMEPAGE FEED TIMESTAMP UPDATE),
        qw(SOURCESET TARGETSET NAME INSTITUTION));

    my @lines = map { "#$_: " . $meta{$_} } grep { defined $meta{$_} } @order;
    return @lines ? join ("\n", @lines) . "\n" : "";
}


sub parse {
    my $self = shift;

    $self->_initparams( @_ );
    $self->_startparsing if defined $self->{from}; # start from new source

    my $line = $self->{lookaheadline};
    $line = $self->_readline() unless defined $line;

    while (defined $line) {
        $self->appendline( $line );
        $line = $self->_readline();
    } 

    return $self->errors == 0;
}


sub nextlink {
    my $self = shift;

    my $line = $self->{lookaheadline};
    if (defined $line) {
        $self->{lookaheadline} = undef;
    } else {
        $line = $self->_readline();
        return unless defined $line; # undef => EOF
    }

    do {
        my @link = $self->appendline( $line );
        return @link if @link; # proceed on empty lines or errors
    } while($line = $self->_readline());

    return; # EOF
}


sub link {
    my $self = shift;
    return @{$self->{link}} if $self->{link};
}


sub expanded {
    my $self = shift;
    if ( $self->{link} ) {
        unless ( $self->{expanded} ) {
            @{$self->{expanded}} = @{$self->{link}};
            $self->_expandlink( $self->{expanded} ) 
        }
        return @{$self->{expanded}};
    }
}


sub expand {
    my $self = shift;

    my @fields = @_ > 0 ? @_ : '';
    @fields = map { s/^\s+|\s+$//g; $_ }
              map { defined $_ ? $_ : '' } @fields;

    return if $fields[0] eq '' or (grep { $_ =~ /\||\n|\r/ } @fields);

    $self->_expandlink( \@fields );

    return unless _is_uri($fields[0]) && _is_uri($fields[3]);

    return @fields;
}


sub expandsource {
    my ($self, $source) = @_;
    return '' unless defined $source;
    $source =~ s/^\s+|\s+$//g;
    return '' if $source eq '';

    $source = $self->{meta}->{PREFIX} . $source
        if defined $self->{meta}->{PREFIX};

    return _is_uri($source) ? $source : ''; 
}


sub appendline {
    my ($self, $line) = @_;
    return unless defined $line;
    chomp $line;

    $self->{line}++;
    $self->{currentline} = $line;
    my @parts = split ('\|',$line);

    return if (@parts < 1 || $parts[0] =~ /^\s*$/ );
    my $link = $self->_fields( @parts );

    my $has_link = $self->appendlink( @$link );

    $self->{currentline} = undef;

    if ( $has_link ) {
        return wantarray ? @{ $self->{link} } : 1;
    }

    return;
}


sub appendlink {
    my $self = shift;

    my @fields = map { defined $_ ? $_ : '' } @_[0..3];
    @fields = map { s/^\s+|\s+$//g; $_ } @fields;

    if ( $fields[0] eq '' ) {
        $self->_handle_error( 'missing source' );
        return;
    } elsif ( grep { $_ =~ /\|/ } @fields ) {
        $self->_handle_error( 'link fields must not contain \'|\'' );
        return;
    } elsif ( grep { $_ =~ /[\n\r]/ } @fields ) {
        $self->_handle_error( 'link fields must not contain line breaks' );
        return;
    }

    my $msg = $self->_checklink( @fields );
    if ( $msg ) {
        $self->_handle_error( $msg ); 
        return;
    }

    # finally got a valid link
    $self->{link} = \@fields;
    $self->{expanded} = undef;
    $self->{meta}->{COUNT}++;

    if ( defined $self->{expected_examples} ) { # examples may contain prefix
        my @idforms = $fields[0];
        my $prefix = $self->{meta}->{PREFIX};
        push @idforms, $prefix . $fields[0] if defined $prefix;
        foreach my $source (@idforms) {
            if ( $self->{expected_examples}->{$source} ) {
                delete $self->{expected_examples}->{$source};
                $self->{expected_examples} = undef 
                    unless keys %{ $self->{expected_examples} };
            }
        }
    }

    if ( $self->{link_handler} ) {
        if ( $self->{link_handler} eq 'print' ) {
            print plainbeaconlink( @fields ) . "\n";
         } elsif ( $self->{link_handler} eq 'expand' ) { 
            print join('|',$self->expanded) . "\n"; 
         } else {
            # TODO: call with expanded link on request
            eval { $self->{link_handler}->( @fields ); };
            if ( $@ ) {
                $self->_handle_error( "link handler died: $@" );
                return;
            }
        }
    }

    return @fields; # TODO: return expanded on request
}


sub beacon {
    return Data::Beacon->new( @_ );
}


sub plainbeaconlink {
    shift if ref($_[0]) and UNIVERSAL::isa($_[0],'Data::Beacon');
    return '' unless @_; 
    my @link = map { defined $_ ? $_ : '' } @_[0..3];
    @link = map { s/^\s+|\s+$//g; $_; } @link;
    return '' if $link[0] eq '';

    if ( $link[3] eq '' ){
        pop @link;
        if ($link[2] eq '') {
            pop @link;
            pop @link if ($link[1] eq '');
        }
    } elsif ( _is_uri($link[3]) ) { # only position of _is_uri where argument may be undefined
        my $uri = pop @link;
        if ($link[2] eq '') {
           pop @link;
           pop @link if ($link[1] eq '');
        }
        push @link, $uri;
    }

    return join('|', @link);
}


sub _initparams {
    my $self = shift;
    my %param;

    if ( @_ % 2 && !blessed($_[0]) && ref($_[0]) && ref($_[0]) eq 'HASH' ) {
        my $pre = shift;
        %param = @_;
        $param{pre} = $pre;
    } else {
        $self->{from} = (@_ % 2) ? shift(@_) : undef;
        %param = @_;
    }

    $self->{from} = $param{from}
        if exists $param{from};

    if ( $param{errors} ) {
        my $handler = $param{errors};
        $handler = $Data::Beacon::ERROR_HANDLERS{lc($handler)}
        unless ref($handler);
        unless ( ref($handler) and ref($handler) eq 'CODE' ) {
            my $msg = 'error handler must be code or ' 
                    . join('/',keys %Data::Beacon::ERROR_HANDLERS)
                    . ', got '
                    . (defined $handler ? $handler : 'undef');
            croak $msg;
        }
        $self->{error_handler} = $handler;
    }

    if ( $param{links} ) {
        my $handler = $param{links};
        croak 'link handler must be code or \'print\' or \'expand\''
            unless $handler =~ /^(print|expand)$/ 
                or (ref($handler) and ref($handler) eq 'CODE');
        $self->{link_handler} = $handler;
    }

    if ( defined $param{pre} ) {
        croak "pre option must be a hash reference"
            unless ref($param{pre}) and ref($param{pre}) eq 'HASH';
        $self->{pre} = $param{pre};
    } elsif ( exists $param{pre} ) {
        $self->{pre} = undef;
    }

    $self->{mtime} = $param{mtime};
}


sub _startparsing {
    my $self = shift;

    # we do not init $self->{meta} because it is set in initparams;
    $self->{meta} = { 'FORMAT' => 'BEACON' };
    $self->meta( %{ $self->{pre} } ) if $self->{pre};
    $self->{line} = 0;
    $self->{link} = undef;
    $self->{expanded} = undef;
    $self->{errors} = 0;
    $self->{lasterror} = [];
    $self->{lookaheadline} = undef;
    $self->{fh} = undef;
    $self->{inputlines} = [];
    $self->{examples} = [];

    return unless defined $self->{from};

    # decide where to parse from
    my $type = ref($self->{from});
    if ($type) {
        if ($type eq 'SCALAR') {
            $self->{inputlines} = [ split("\n",${$self->{from}}) ];
        } elsif ($type ne 'CODE') {
            $self->_handle_error( "Unknown input $type" );
            return;
        }
    } elsif( $self->{from} eq '-' ) {
        $self->{fh} = \*STDIN;
    } else {
        if(!(open $self->{fh}, $self->{from})) {
            $self->_handle_error( 'Failed to open ' . $self->{from} );
            return;
        }
    }

    # initlialize TIMESTAMP
    if ($self->{mtime}) {
        my @stat = stat( $self->{from} );
        $self->meta('TIMESTAMP', gmtime( $stat[9] )->datetime() . 'Z' );
    }

    # start parsing
    my $line = $self->_readline();
    return unless defined $line;
    $line =~ s/^\xEF\xBB\xBF//; # UTF-8 BOM (optional)

    do {
        $line =~ s/^\s+|\s*\n?$//g;
        if ($line eq '') {
            $self->{line}++;
        } elsif ($line =~ /^#([^:=\s]+)(\s*[:=]?\s*|\s+)(.*)$/) {
            $self->{line}++;
            eval { $self->meta($1,$3); };
            if ($@) {
                my $msg = $@; $msg =~ s/ at .*$//;
                $self->_handle_error( $msg, $line );
            }
        } else {
            $self->{lookaheadline} = $line;
            return;
        }
        $line = $self->_readline();
    } while (defined $line);
}


sub _handle_error {
    my $self = shift;
    my $msg = shift;
    my $line = shift || $self->{currentline} || '';
    chomp $line;
    $self->{lasterror} = [ $msg, $self->{line}, $line ];
    $self->{errors}++;
    $self->{error_handler}->( $msg, $self->{line}, $line ) if $self->{error_handler};
}

our %ERROR_HANDLERS = (
    'print' => sub {
        my ($msg, $lineno) = @_;
        $msg .= " at line $lineno" if $lineno ;
        print STDERR "$msg\n";
    },
    'warn' => sub {
        my ($msg, $lineno) = @_;
        $msg .= " at line $lineno" if $lineno;
        carp $msg;
    },
    'die' => sub {
        my ($msg, $lineno) = @_;
        $msg .= " at line $lineno" if $lineno;
        croak $msg;
    }
);


sub _readline {
    my $self = shift;
    if ($self->{fh}) {
        return eval { no warnings; readline $self->{fh} };
    } elsif (ref($self->{from}) && ref($self->{from}) eq 'CODE') {
        my $line = eval { $self->{from}->(); };
        if ($@) { # input handler died
            $self->_handle_error( $@, '' );
            $self->{from} = undef;
        }
        return $line;
    } else {
        return @{$self->{inputlines}} ? shift(@{$self->{inputlines}}) : undef;
    }
}


sub _fields {
    my $self = shift;
    my @parts = @_;

    my $n = scalar @parts;

    my $link = [shift @parts,"","",""];

    my $target = $self->{meta}->{TARGET};
    my $targetprefix = $self->{meta}->{TARGETPREFIX};
    if ($target or $targetprefix) {
        $link->[1] = shift @parts if @parts;
        $link->[2] = shift @parts if @parts;
        # TODO: do we want both #TARGET links and explicit links in one file?
        $link->[3] = shift @parts if @parts;
    } else {
        $link->[3] = pop @parts
            if ($n > 1 && _is_uri($parts[$n-2]));
        $link->[1] = shift @parts if @parts;
        $link->[2] = shift @parts if @parts;
    }

     return $link
}

sub _checklink {
    my ($self, @fields) = @_;

    my @exp = @fields;
    # TODO: check only - we don't need full expansion
    $self->_expandlink( \@exp );

    return "source is no URI: ".$exp[0]
        unless _is_uri($exp[0]);

    # TODO: we could encode bad characters etc.
    return "target is no URI: ".$exp[3]
        unless _is_uri($exp[3]);

    return undef;
}


sub _expandlink {
    my ($self, $link) = @_;

    my $prefix = $self->{meta}->{PREFIX};

    my $source = $link->[0];

    # TODO: document this expansion
    if ( $link->[1] =~ /^[0-9]*$/ ) { # if label is number (of hits) or empty
        my $label = $link->[1];
        my $descr = $link->[2];

        # TODO: handle zero hits
        my $msg = $self->{meta}->{$label eq '1' ? 'ONEMESSAGE' : 'SOMEMESSAGE'}
                || $self->{meta}->{'MESSAGE'};

        if ( defined $msg ) {
            _str_replace( $msg, '{id}', $link->[0] ); # unexpanded
            _str_replace( $msg, '{hits}', $link->[1] );
            _str_replace( $msg, '{label}', $link->[1] );
            _str_replace( $msg, '{description}', $link->[2] ); 
            _str_replace( $msg, '{target}', $link->[3] ); # unexpanded
        } else {
            $msg = $self->{meta}->{'NAME'} || $self->{meta}->{'INSTITUTION'};
        }
        if ( defined $msg && $msg ne '' ) {
            # if ( $link->[1] == "") $descr = $label;
            $link->[1] = $msg;
            $link->[1] =~ s/^\s+|\s+$//g;
            $link->[1] =~ s/\s+/ /g;
        }
    } else {
        _str_replace( $link->[1], '{id}', $link->[0] ); # unexpanded
        _str_replace( $link->[1], '{description}', $link->[2] );
        _str_replace( $link->[1], '{target}', $link->[3] ); # unexpanded
        # trim label, because it may have changed
        $link->[1] =~ s/^\s+|\s+$//g;
        $link->[1] =~ s/\s+/ /g;
    }

    # expand source
    $link->[0] = $prefix . $link->[0] if defined $prefix;

    # expand target
    my $target = $self->{meta}->{TARGET};
    my $targetprefix = $self->{meta}->{TARGETPREFIX};
    if (defined $target) {
        $link->[3] = $target;
        my $label = $link->[1];
        $link->[3] =~ s/{ID}/$source/g;
    } elsif( defined $targetprefix ) {
        $link->[3] = $targetprefix . $link->[3];
    }

    return @$link;
}

sub _str_replace {
    $_[0] =~ s/\Q$_[1]\E/$_[2]/g;
}


sub _is_uri {
    my $value = $_[0];
    
    return unless defined($value);
    
    # check for illegal characters
    return if $value =~ /[^a-z0-9\:\/\?\#\[\]\@\!\$\&\'\(\)\*\+\,\;\=\.\-\_\~\%]/i;
    
    # check for hex escapes that aren't complete
    return if $value =~ /%[^0-9a-f]/i;
    return if $value =~ /%[0-9a-f](:?[^0-9a-f]|$)/i;
    
    # split uri (from RFC 3986)
    my($scheme, $authority, $path, $query, $fragment)
      = $value =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

    # scheme and path are required, though the path can be empty
    return unless (defined($scheme) && length($scheme) && defined($path));
    
    # if authority is present, the path must be empty or begin with a /
    if(defined($authority) && length($authority)){
        return unless(length($path) == 0 || $path =~ m!^/!);    
    } else {
        # if authority is not present, the path must not start with //
        return if $path =~ m!^//!;
    }
    
    # scheme must begin with a letter, then consist of letters, digits, +, ., or -
    return unless lc($scheme) =~ m!^[a-z][a-z0-9\+\-\.]*$!;
    
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Beacon - BEACON format validating parser and serializer

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

  use Data::Beacon;

  $beacon = beacon();                     # create new Beacon object
  $beacon = beacon( {                     # create new Beacon with meta fields
    PREFIX => $p, TARGET => $t, XY => $z
  } );
  
  $beacon = beacon( $filename );          # open file and parse its meta fields

  if ( $b->errors ) {                     # check for errors
    print STDERR $b->lasterror . "\n"
    ($msg,$lineno,$line) = $b->lasterror; 
  }

  $beacon->parse;                         # parse all links from opened file
  $beacon->parse( links => \&handler );   # parse links, call handler for each

  $beacon->parse( errors => \&handler );  # parse links, on error call handler
  $beacon->parse( errors => 'print' );    # parse links, print errors to STDERR
  $beacon->parse( errors => 'warn' );     # parse links, warn on errors
  $beacon->parse( errors => 'die' );      # parse links, die on errors

  while ( $beacon->nextlink ) {            # parse and iterate all valid links
    ($source,$label,$descr,$target) = $beacon->link;      # raw link as read
    ($source,$label,$descr,$target) = $beacon->expanded;  # full link expanded
  }

  $descr = $beacon->meta( 'DESCRIPTION' );      # get meta field
  $beacon->meta( DESCRIPTION => 'my links' );   # set meta fields
  %meta = $beacon->meta;                        # get all meta fields

  print $beacon->metafields;                    # serialize meta fields


  $beacon->parse( \$beaconstring );             # parse from string
  $beacon->parse( sub { return $nextline } );   # parse from callback

  $beacon->count;        # number of parsed links

  
  $beacon->appendline( $line );

  $beacon->appendlink( $source, $label, $descr, $target );

=head1 DESCRIPTION

THIS MODULE DOES NOT REFLECT THE CURRENT STATE OF BEACON SPECIFICATION!

This package implements a validating L</BEACON format> parser and serializer.
In short, a "Beacon" is a set of links, together with some meta fields. Each 
link at least consists of "source" URI (also referred to as "id") and a "target"
URI. In addition it has a "label" and a "description", which are both Unicode
strings, being the empty string by default.

=head1 BEACON format

B<BEACON format> is the serialization format for Beacons. It defines a very
condense syntax to express links without having to deal much with technical 
specifications.

See L<http://gbv.github.com/beaconspec/beacon.html> for a more detailed
description.

=head1 USAGE

=head2 Serializing

To serialize only BEACON meta fields, create a new Beacon object, and set its
meta fields (passed to the constructor, or with L</meta>). You can then get 
the meta fields in BEACON format with L</metafields>:

  my $beacon = beacon( { PREFIX => ..., TARGET => ... } );
  print $beacon->metafields;

The easiest way to serialize links in BEACON format, is to set your Beacon 
object's link handler to C<print>, so each link is directly printed to STDOUT.

  my $beacon = beacon( \%metafields, links => 'print' );
  print $b->metafields();

  while ( ... ) {
      $beacon->appendlink( $source, $label, $description, $target );
  }

Alternatively you can use the function L</plainbeaconlink>. In this case you
should validate links before printing:

  if ( $beacon->appendlink( $source, $label, $description, $target ) ) {
      print plainbeaconlink( $beacon->link ) . "\n";
  }

=head2 Parsing

You can parse BEACON format either as iterator:

  my $beacon = beacon( $file );
  while ( $beacon->nextlink ) {
      my ($source, $label, $description, $target) = $beacon->link;
      ...
  }

Or by push parsing with handler callbacks:

  my $beacon = beacon( $file );
  $beacon->parse( 'link' => \link_handler );
  $errors = $beacon->errors;

Instead of a filename, you can also provide a scalar reference, to parse
from a string. The meta fields are parsed immediately:

  my $beacon = beacon( $file );
  print $beacon->metafields . "\n";
  my $errors = $beacon->errors;

To quickly parse a BEACON file:

  use Data::Beacon;
  beacon($file)->parse();

=head2 Querying

Data::Beacon does only read or write links. To store links, use one of
its subclasses (to be described later).

=head2 Handlers

To handle errors and links, you can pass handler arguments to the constructor
and to the L</parse> method.

=over

=item C<errors>

By default, errors are silently ignored (C<errors =E<gt> 0>. You should enable
one of the error handlers C<warn> (errors create a warning with C<carp>), 
C<die> (errors will let the program die with C<croak>), or C<print> (error 
messages will be print to STDERR). Alternatively you can provide a custom error
handler function as code reference. On error this function is provided one to
three arguments: first an error message, second a line number, and third the
content of the current line, if the error resulted in parsing a line of BEACON
format.

=item C<links>

See the L</parse> method for description.

=back

=head1 METHODS

=head2 new ( [ $from ] [, $metafields ] [, $handlers ] )

Create a new Beacon object, optionally from a given file. If you specify a 
source via C<$from> argument or as handler C<from =E<gt> $from>, it will be
opened for parsing and all meta fields will immediately be read from it.
Otherwise a new Beacon object will be created, optionally with given meta
fields.

=head2 meta ( [ $key [ => $value [ ... ] ] ] )

Get and/or set one or more meta fields. Returns a hash (no arguments),
or string or undef (one argument), or croaks on invalid arguments. A
meta field can be unset by setting its value to the empty string.
The FORMAT field cannot be unset. This method may also croak if a known
fields, such as FORMAT, PREFIX, FEED, EXAMPLES, REVISIT, TIMESTAMP is
tried to set to an invalid value. Such an error will not change the
error counter of this object or modify C<lasterror>.

=head2 count

If parsing has been started, returns the number of links, successfully read so
far (or zero). If only the meta fields have been parsed, this returns the value
of the meta field. In contrast to C<meta('count')>, this method always returns
a number. Note that all valid links that could be parsed are included, no matter
if processed by a link handler or not.

=head2 line

Returns the current line number or zero.

=head2 lasterror

Returns the last parsing error message (if any). Errors triggered by directly
calling C<meta> are not included. In list context returns a list of error
message, line number, and current line content.

=head2 errors

Returns the number of parsing errors or zero.

=head2 metafields 

Return all meta fields, serialized and sorted as string. Althugh the order of
fields is irrelevant, but this implementation always returns the same fields
in same order. To get all meta fields as hash, use the C<meta> method.

=head2 parse ( [ $from ] { handler => coderef | option => $value } )

Parse all remaining links (push parsing). If provided a C<from> parameter,
this starts a new Beacon. That means the following three are equivalent:

  $b = new SeeAlso::Beacon( $from );

  $b = new SeeAlso::Beacon( from => $from );

  $b = new SeeAlso::Beacon;
  $b->parse( $from );

If C<from> is a scalar, it is used as file to parse from. Alternatively you
can supply a string reference, or a code reference.

The C<pre> option can be used to set some meta fields before parsing starts.
These fields are cached and reused every time you call C<parse>.

If the C<mtime> option is given, the TIMESTAMP meta value will be initialized
as last modification time of the given file.

By default, all errors are silently ignored, unless you specifiy an error handler
The last error can be retrieved with the C<lasterror> method. The current number
of errors by C<errors>.

Finally, the C<link> handler can be a code reference to a method that is
called for each link (that is each line in the input that contains a valid
link). The following arguments are passed to the handler:

=over

=item C<$source>

Link source as given in BEACON format.
This may be abbreviated but not the empty string.

=item C<$label>

Label as string. This may be the empty string.

=item C<$description>

Description as string. This may be the empty string.

=item C<$target>

Link target as given in BEACON format.
This may be abbreviated or the empty string.

=back

The number of sucessfully parsed links is returned by C<count>.

Errors in link handler and input handler are catched, and produce an
error that is given to the error handler.

=head2 nextlink

Read from the input stream until the next link has been parsed. Empty lines
and invalid lines are skipped, but the error handler is called on invalid 
lines. This method can be used for pull parsing. Always returns either the
link as list or an empty list if the end of input has been reached.

=head2 link

Returns the last valid link, that has been read. The link is returned
as list of four values (source, label, description, target) without
expansion. Use the L</expanded> method to get the link with full URIs.

=head2 expanded

Returns the last valid link, that has been read in expanded form. The 
link is returned as list of four values (source, label, description, 
target), possibly expanded by the meta fields PREFIX, TARGET/TARGETPREFIX,
MESSAGE etc. Use L</expand> to expand an arbitrary link.

=head2 expand ( $source, $label, $description, $target )

Expand a link, consisting of source (mandatory), and label, description,
and target (all optional). Returns the expanded link as array with four 
values, or an empty list. This method does append the link to the Beacon
object, nor call any handlers.

=head2 expandsource( $source )

Expand the source part of a link, by prepending the PREFIX meta field, if 
given. This method always returns a string, which is the empty string, if
the source parameter could not be expanded to a valid URI.

=head2 appendline( $line )

Append a line of of BEACON format. This method parses the line, and calls the
link handler, or error handler. In scalar context returns whether a link has
been read (that can then be accessed with C<link>). In list context, returns
the parsed link as list, or the empty list, if the line could not be parsed.

=head2 appendlink ( $source [, $label [, $description [, $target ] ] ] )

Append a link. The link is validated and returned as list of four values.
On error the error handler is called and an empty list is returned.
On success the link handler is called.

=head1 FUNCTIONS

The following functions are exported by default.

=head2 beacon ( [ $from ] { handler => coderef } )

Shortcut for C<Data::Beacon-E<gt>new>.

=head2 plainbeaconlink ( $source, $label, $description, $target )

Serialize a link, consisting of source (mandatory), label, description,
and target (all optional) as condensed string in BEACON format. This
function does not check whether the arguments form a valid link or not.
You can pass a simple link, as returned by the L</link> method, or an
expanded link, as returned by L</expanded>.

This function will be removed or renamed.

=head1 INTERNAL METHODS

If you directly call any of this methods, puppies will die.

=head2 _initparams ( [ $from ] { handler => coderef | option => value } | $metafield )

Initialize parameters as passed to C<new> or C<parse>. Known parameters
are C<from>, C<error>, and C<link> (C<from> is not checked here). In 
addition you cann pass C<pre> and C<mtime> as options.

=head2 _startparsing

Open a BEACON file and parse all meta fields. Calling this method will reset
the whole object but not the parameters as set with C<_initparams>. If no
source had been specified (with parameter C<from>), this is all the method 
does. If a source is given, it is opened and parsed. Parsing stops when the
first non-empty and non-meta field line is encountered. This line is internally
stored as lookahead.

=head2 _handle_error ( $msg [, $line ] )

Internal error handler that calls a custom error handler,
increases the error counter and stores the last error. 

=head2 _readline

Internally read and return a line for parsing afterwards. May trigger an error.

=head2 _fields

Gets one or more fields, that are strings, which do not contain C<|> or
newlines. The first string is not empty. Returns a reference to an array
of four fields.

=head2 _expandlink ( $link )

Expand a link, provided as array reference without validation. The link
must have four defined, trimmed fields. After expansion, source and target
must still be checked whether they are valid URIs.

=head2 _is_uri

Check whether a given string is an URI. This function is based on code of
L<Data::Validate::URI>, adopted for performance.

=head1 SEE ALSO

See also L<SeeAlso::Server> for an API to exchange single sets of 
beacon links, based on the same source identifier.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
