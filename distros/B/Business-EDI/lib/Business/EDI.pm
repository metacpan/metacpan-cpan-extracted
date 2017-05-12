package Business::EDI;

use strict;
use warnings;
use Carp;
# use Data::Dumper;

our $VERSION = 0.05;

use UNIVERSAL::require;
use Data::Dumper;
use File::Spec;
use CGI qw//;
use Business::EDI::CodeList;
use Business::EDI::Composite;
use Business::EDI::DataElement;
use Business::EDI::Segment;
use Business::EDI::Spec;

our $debug = 0;
our %debug = ();
our $error;          # for the whole class
my %fields = ();

our $AUTOLOAD;
sub DESTROY {}  #
sub AUTOLOAD {
    my $self  = shift;
    my $class = ref($self) or croak "AUTOLOAD error: $self is not an object, looking for $AUTOLOAD";
    my $name  = $AUTOLOAD;

    $name =~ s/.*://;                # strip leading package stuff
    $name =~  /^syntax/          or  # leave syntax, 
    $name =~  /^SG\d+$/          or  # leave SGxx alone (for segment groups)
    $name =~ s/^s(eg(ment)?)?//i or  # strip segment (a prefix to avoid numerical method names)
    $name =~ s/^p(art)?//i;          # strip part -- autoload's parallel accessor, e.g. ->part4343 to ->part(4343)

    $debug and warn "AUTOLOADING '$name' for " . $class;

    if (exists $self->{_permitted}->{$name}) {  # explicitly named accessible fields
        if (@_) {
            return $self->{$name} = shift;
        } else {
            return $self->{$name};
        }
    }
    
    if (ref $self->{def} eq 'ARRAY') {          # spec defined subelements
        if ($name =~ s/^all_(.+)$/$1/i) {
            @_ and croak "AUTOLOAD error: all_$name is read_only, rec'd argument(s): " .  join(', ', @_);
            if ($debug) {
                warn "AUTOLOADing " . $self->{code} . "/all_$name (from " . scalar(@{$self->{array}}) . " arrayed elements): "
                        . join(' ', map {$_->{code}} @{$self->{array}});
                $debug > 1 and print STDERR Dumper($self), "\n";
            }
            my $target = $name =~ /^SG\d+$/ ? ($self->{code} . "/$name") : $name;
            return grep {$_->{code} and $_->{code} eq $target} @{$self->{array}};    # return array 
        }
        return __PACKAGE__->_deepload_array($self, $name, @_); # not $self->_deepload - avoid recursion
    }
    # lastly, try to reach through any Cxxx Composites, if the target is unique
    return __PACKAGE__->_deepload($self, $name, @_);           # not $self->_deepload - avoid recursion
}

sub _deepload_array {
    my $pkg  = shift; # does nothing
    my $self = shift or return;
    my $name = shift or return;
    unless ($self->{def}) {
        die "_deepload_array of '$name' attempted on an object that does not have a spec definition";
        return;
    }

    my @hits     = grep {$_->{code} eq $name} @{$self->{def}};
    my $defcount = scalar @{$self->{def}};
    my $hitcount = scalar @hits;
    my $total_possible = 0;
    foreach (@hits) {
        $total_possible += ($_->{repeats} || 1);
    }
    $name =~ /^SG\d+$/ and $name = $self->{message_code} . "/$name";    # adjust key for SGs
    $debug and warn "Looking for '$name' matches $hitcount of $defcount subelements, w/ $total_possible instances: " . join(' ', map {$_->{code}} @hits);
    $debug and warn ref($self) . " self->{array} has " . scalar(@{$self->{array}}) . " elements of data";
    
    # Logic: 
    # If there is only one possible element to match, then we can read/write to it.
    # But if there are multiple repetitions possible, then we cannot tell which one to target,
    # UNLESS it is a read operation and there is only one such element populated.  
    # Write operation still would be indifferentiable between new element constructor and existing elememt overwrite.
    if ($total_possible == 1 or ($hitcount == 1 and not @_)) {
        foreach (@{$self->{array}}) {
            $_->code eq $name or next;
            if (@_) {
                return $_ = shift;
            } else {
                return $_;
            }
        }
        # if we got here, it's a valid target w/ no populated value (no code match)
        return;
        # @_ or return $self->_subelement_helper($name, {}, $self->{message_code});   # so you get an empty object of the correct type on read
        # TODO: for 1-hit write, splice in at the correct position.  Tricky.
    } elsif ($total_possible == 0) {
        $debug and $debug > 1 and print STDERR "FAILED _deepload_array of '$name' in object: ", Dumper($self);
    }
    croak "AUTOLOAD error: Cannot " . (@_ ? 'write' : 'read') . " '$name' field of class '" . ref($self)
          . "', $hitcount matches ($total_possible repetitions) in subelements";
}

sub _deepload {
    my $pkg  = shift; # does nothing
    my $self = shift    or return;
    my $name = shift    or return;
    $self->{_permitted} or return;

    my @partkeys = $self->part_keys;
    my @keys     = grep {/^C\d{3}$/} @partkeys;
    my $allcount = scalar(@partkeys);
    my $ccount   = scalar(@keys);
    $debug and warn "Looking for $name under $allcount subelements, $ccount Composites: " . join(' ', @keys);

    my @hits = grep {$name eq $_} @partkeys;
    if (scalar @hits) {
        
    } elsif ($ccount) {
        my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can autoload objects";
        my $part = $spec->get_spec('composite');
        foreach my $code (@keys) {
            $part->{$code} or croak(ref($self) . " Object _permitted composite code '$code' not found in spec version " . $spec->version);
            my @subparts = grep {$_->{code} eq $name} @{$part->{$code}->{parts}};
            @subparts and push(@hits, map {$code} @subparts);   
            # important here, we add the Cxxx code once per hit in its subparts.  Multiple hits means we cannot target cleanly.
        }
    }
    my $hitcount = scalar(@hits);
    $debug and warn "Found $name has $hitcount possible match(es) in $ccount Composites: " . join(' ', @hits);
    if ($hitcount == 1) {
        if (@_) {
            return $self->{$hits[0]}->{$name} = shift;
        } else {
            return $self->{$hits[0]}->{$name};
        }
    } elsif ($hitcount > 1) {
        croak "AUTOLOAD error: Cannot access '$name' field of class '" . ref($self) . "', "
            . " $hitcount indeterminate matches in collapsable subelements";
    }
    # else hitcount == 0
    $debug and $debug > 1 and print STDERR "FAILED _deepload of '$name' in object: ", Dumper($self);
    croak "AUTOLOAD error: Cannot access '$name' field of class '" . ref($self)
        . "' (or $allcount collapsable subelements, $ccount Composites)";
}

# Constructors

sub new {
    my $class = shift;
    my %args;
    if (scalar @_ eq 1) {
        $args{version} = shift;
    } elsif (@_) {
        scalar(@_) % 2 and croak "Odd number of arguments to new() incorrect.  Use (name1 => value1) style.";
        %args = @_;
    }
    my $stuff = {_permitted => {(map {$_ => 1} keys %fields)}, %fields};
    foreach (keys %args) {
        $_ eq 'version' and next;  # special case
        exists ($stuff->{_permitted}->{$_}) or croak "Unrecognized argument to new: $_ => $args{$_}";
    }
    my $self = bless($stuff, $class);
    if ($args{version}) {
        $self->spec(version => $args{version}) or croak "Unrecognized spec version '$args{version}'";
    }
    $debug and $debug > 1 and print Dumper($self);
    return $self;
}

# BIG Complicated META-Constructors!!

sub _common_constructor {
    my $self = shift;
    my $type = shift or die "Internal error: _common_constructor called without required argument for object type";
    my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can create $type objects";
    my $part = $spec->get_spec($type);
    my $code = uc(shift) or croak "No $type code specified";
    my $body = shift;

    $part->{$code} or return $self->carp_error("$type code '$code' is not found amongst "
        . scalar(keys %$part) ." ". $type . "s in spec version " . $spec->version); # . ": " . Dumper([sort keys %$part]));

    unless (ref($body) eq 'HASH') {
        return $self->carp_error("body argument for $type must be HASHREF, not '" . ref($body) . "'");
    }
    my @subparts = map {$_->{code}} @{$part->{$code}->{parts}};
    my @required = map {$_->{code}} grep {$_->{mandatory}} @{$part->{$code}->{parts}};

    my ($compspec, @compcodes);
    my ( $segspec, @seggroups);
    foreach (@subparts) {
        /^SG\d+$/  and push(@seggroups, $_) and next;
        /^C\d{3}$/ and push(@compcodes, $_) and next;
    }
    $compspec = $spec->get_spec('composite') if @compcodes;
  # $segspec  = $spec->get_spec('segment')   if @seggroups;

    my $normal;
    # Now we normalize the body according to the spec (apply wrappers)
    foreach my $key (keys %$body) {
        if (grep {$key eq $_} @subparts) {
            $normal->{$key} = $body->{$key};    # simple case
            next;
        }
        elsif (@compcodes) {
            my @hits;
            foreach my $compcode (@compcodes) {
                push @hits, map {$compcode} grep {$_->{code} eq $key} @{$compspec->{$compcode}->{parts}};
            }
            if (scalar(@hits) == 1) {
                $normal->{$hits[0]}->{$key} = $body->{$key};    # only one place for it to go, so apply the wrapper
                next;
            } elsif (scalar(@hits) > 1) {
                return $self->carp_error("$type subpart '$key' has " . scalar(@hits)
                    . " indeterminate matches under composites: " . join(', ', @hits)
                );
            }
            return $self->carp_error("$type subpart '$key' not found in spec " . $spec->version);
        }
    }

    $debug and printf STDERR "creating $type/$code with %d spec subpart(s): %s\n", scalar(@subparts), join(' ', @subparts);
    # push @subparts,  'debug';
    my $unblessed = $self->unblessed($normal, \@subparts);
    $unblessed or return;
    my $new = bless($unblessed, __PACKAGE__ . '::' . ucfirst($type));
    $new->spec($spec);
    $new->{_permitted}->{code}  = 1;
    $new->{_permitted}->{label} = 1;
    $new->{code}  = $code;
    $new->{label} = $part->{$code}->{label};
    # $new->debug($debug{$type}) if $debug{$type};
    foreach (@required) {
        unless (defined $new->part($_)) {
            return $self->carp_error("Required field $type/$code/$_ not populated");
        }
    }
    return $new;
}

sub _def_based_constructor {
    my $self = shift;
    my $type = shift or die "Internal error: _def_based_constructor called without required argument for object type";
    my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can create $type objects";
    my $page = $self->spec_page($type);  # page of the spec
    my $code = uc(shift) or croak "No $type code specified";
    my $body = shift;
    my $message_code = (@_ and $_[0]) ? shift : '';
    my $page_code;

    if ($type eq 'message') {
        $message_code = $code;
        $page_code    = $code;
    } elsif ($type eq 'segment_group') {
        $code =~ /^SG\d+$/ and $message_code and $code = "$message_code/$code";
        $code =~ /^(\S+)\/(SG\d+)$/ or return $self->carp_error("Cannot spec $type '$code' without message.  Use xpath style, like 'ORDERS/SG27'");
        $page = $page->{$1} or return $self->carp_error("Message $1 does not have any " . $type . "s in spec version " . $spec->version);
        $message_code = $1;
        $page_code    = $2;
        # tighen spec down past message level based on first part of key
    }

    unless (ref($body) eq 'ARRAY') {
        return $self->carp_error("body argument to $type() must be ARRAYREF, not '" . ref($body) . "'");
    }

    my @subparts = @{$page->{$page_code}->{parts}};
    $debug and printf STDERR "creating $type/$code with %d spec subpart(s): %s\n", scalar(@subparts), join(' ', map {$_->{code}} @subparts);
    $debug and print STDERR "calling \$self->unblessed_array(\$body, \$page->{$page_code}->{parts}, '$message_code')\n";
    my $unblessed = $self->unblessed_array($body, \@subparts, $message_code);     # doesn't yet support arrayref(?)
    $unblessed or return;
    my $new = bless($unblessed, __PACKAGE__ . '::' . ucfirst($type));
    $new->spec($spec);
    $new->{_permitted}->{code}         = 1;
    $new->{_permitted}->{message_code} = 1;
    $new->{_permitted}->{label}        = 1;
    $new->{code} = $code;
    $new->{message_code} = $message_code;   # same as code for messages, different for SGs
    $new->{label} = $page->{$page_code}->{label};
    if ($type eq 'segment_group') {
        $new->{sg_code}  = $page_code;   
    }
    return $new;
}

# Fundamental constructor calls for different object types
# These are here so you can just "use Business::EDI;" and not have to worry about using different 
# modules for different data objects.  

sub segment {
    my $self = shift;
    return $self->_common_constructor('segment', @_);
}

sub segment_group {
    my $self = shift;
    return $self->_def_based_constructor('segment_group', @_);
# The difference is that segment_group must deal with repeatable segments, other segment groups, etc.
}

# TODO: rename detect_version one something more clueful
# The difference is that message() expects you to have declared an EDI spec version already, whereas detect_version
# just looks at the contents of the passed data, attempting to extract the encoded version there.

sub detect_version {
    my $self = shift;
    return Business::EDI::Message->new(@_);
}

sub message {
    my $self = shift;
   # my $msg_code = shift;
    #print Dumper ($body);
    return $self->_def_based_constructor('message', @_);
}

sub dataelement {
    my $self = shift;
    # Business::EDI::DataElement->require;
    Business::EDI::DataElement->new(@_);
}

sub composite {
    my $self = shift;
    # Business::EDI::DataElement->require;
    Business::EDI::Composite->new(@_);
}

sub codelist {
    my $self = shift;
    # my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can create objects";
    # my $part = $spec->get_spec('message');
    Business::EDI::CodeList->new_codelist(@_);
}

sub spec_page {
    my $self = shift;
    my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can retrieve part of it";
    @_ or return carp_error("Missing argument to spec_page()");
    return $spec->get_spec(@_); # not $self->get_spec .... sorry
}

sub get_spec {
    my $self = shift;
    @_ or return carp_error("Missing argument to get_spec()");
    return Business::EDI::Spec->new(@_);
}

# Accessor get/set methods

sub code {
    my $self = shift;
    @_ and $self->{code} = shift;
    return $self->{code};
}

sub spec {        # spec(code)
    my $self = shift;
    if (@_) {                                        #  Arg(s) mean we are constructing
        ref($self) or return $self->get_spec(@_);    #  Business::EDI->spec(...) style, class method: simple constructor
        if (ref($_[0]) eq 'Business::EDI::Spec') {   # TODO: use isa or whatever the hip OO style of role-checking is
            $self->{spec} = shift;                   #  We got passed a full spec object, just set
        } else {
            $self->{spec} = $self->get_spec(@_);     #  otherwise construct and retain
        }
    }
    ref($self) or croak "Cannot use class method Business::EDI->spec as an accessor (spec is uninstantiated).  " .
        "Get a spec'd object first like: Business::EDI->new('d87a')->spec, " .
        "or specify the version you want: Business::EDI->spec('default') or Business::EDI->get_spec('default')";
    return $self->{spec};
}

sub error {
    my ($self, $msg, $quiet) = @_;
    $msg or return $self->{error} || $error;  # just an accessor
    ($debug or ! $quiet) and carp $msg;
    return $self->{error} = $msg;
}

sub carp_error {
    my $obj_or_message = shift;
    my $msg;
    if (@_) {
        $msg = (ref($obj_or_message) || $obj_or_message) . ' - ' . shift;
    } else {
        $msg = $obj_or_message;
    }
    if (ref $obj_or_message) {
        # do something?
    }
    carp $msg;
    return;     # undef: important!
}

# ->unblessed($body, \@codes)

sub unblessed {     # call like Business::EDI->unblessed(\%hash, \@codes);
    my $class    = shift;
    my $body     = shift;
    my $codesref = shift;
    $body     or return carp_error "1st required argument to unblessed() is EMPTY";
    $codesref or return carp_error "2nd required argument to unblessed() is EMPTY";
    unless (ref($body)     eq 'HASH') {
        return carp_error "1st argument to unblessed() must be HASHREF, not '" . ref($body) . "'";
    }
    unless (ref($codesref) eq 'ARRAY') {
        return carp_error "2nd argument to unblessed() must be ARRAYREF, not '" . ref($codesref) . "'";
    }
    $debug and printf STDERR "good: unblessed() got body and definition: %s/%s topnodes/defs\n", scalar(keys %$body), scalar(@$codesref); #, Dumper($body), "\n";
    my $self = {};
    foreach (@$codesref) {
        $self->{_permitted}->{$_} = 1;
        $body->{$_} or next;
        $self->{$_} = Business::EDI->subelement({$_ => $body->{$_}}) || $body->{$_};
    }
    return $self;
}

# array based object creation (segment groups)
# allows repeatable subobjects
# enforces mandatory subobjects
sub unblessed_array {     # call like Business::EDI->unblessed_array(\@pseudo_hashes, \@code_objects);
    my $class    = shift;
    my $body     = shift;
    my $codesref = shift;
    my $msg = (@_ and $_[0]) ? shift : '';
 #   my $msg = 'ORDRSP';
    my $strict   = 0;
    $body     or return carp_error "1st required argument 'x' to unblessed_array(x,y,'$msg') is EMPTY";
    $codesref or return carp_error "2nd required argument 'y' to unblessed_array(x,y,'$msg') is EMPTY";
    unless (ref($body)     eq 'ARRAY') {
        return carp_error "1st argument to unblessed_array() must be ARRAYREF, not '" . ref($body) . "'";
    }
    unless (ref($codesref) eq 'ARRAY') {
        return carp_error "2nd argument to unblessed_array() must be ARRAYREF, not '" . ref($codesref) . "'";
    }
    $debug and printf STDERR "good: unblessed_array() got body and definition: %s/%s topnodes/defs\n", scalar(@$body), scalar(@$codesref); #, Dumper($body), "\n";
    my $self = {
        array => [],    # subelements get pushed in here
        def => $codesref,
        _permitted => {array => 1, def => 1},
    };

    my     $sg_specs = $class->spec_page('segment_group') or croak "Cannot get Segment Group definitions";
    my $msg_sg_specs = $sg_specs->{$msg} or croak "ERROR: $msg Segment Groups not defined in spec";
    my $codecount = scalar @$codesref;
    my $j = 0;  # index for @$codesref
    my $repeats = 0;
    my $last_matched = '';
    my $i;
    if (@$body == 2 and ref($body->[0]) eq '') {
        # push @{$self->{array}}, $class->_subelement_helper($body->[0], $body->[1], $msg);
        # return $self;
        $body = [ [$body->[0], $body->[1]] ];
    }

    BODYPART: for ($i=0; $i < @$body; $i++) {
        my $bodypart = $body->[$i];
        # next if ref($bodypart) =~ /)^Business::EDI::/;
        unless (ref($bodypart) eq 'ARRAY') {
            warn "Malformed data.  Bodypart $i is expected to be pseudohash ARRAYREF, not "
                . (ref($bodypart) || "a scalar='$bodypart'") . ".  Skipping it...";
            next;
        }
        my $key = $bodypart->[0];
        $debug and print "BODYPART $i: $key\n";
        while ($j < $codecount) {
            my $def = $codesref->[$j];
            $debug and printf STDERR "BODYPART $i: $key comparing to def $j: %5s  %s\n", $def->{code}, ($key eq $def->{code} ? 'MATCH!' : '');
            if ($key eq $def->{code}) {
                $last_matched = $key;
                my $limit = $def->{repeats};     # checking the PREVIOUS def to see if it allows repetition
                if (++$repeats <= $limit) {
                    push @{$self->{array}}, $class->_subelement_helper($key, $bodypart->[1], $msg);
                } else {
                    $strict and die "Code '$key' is limited to $limit occurrences.  Dropping data!!";
                    warn "Code '$key' is limited to $limit occurrences.  Dropping data!!";
                }
                next BODYPART;
            }
            # check if this def was mandatory (satisfied if we already added it)
            if ($def->{mandatory} and $def->{code} !~ /^UN.$/ and not $repeats) {
                my $msg = "Mandatory code '" . $def->{code} . "' from definition $j missing or out of position (last found '$key' at position $i)";
                $strict and return carp_error $msg;
                $debug and warn $msg;
            }
            $repeats = 0;
            $j++;   # move the index to the next rule
        }
        # now either we matched, or we ran out of tries
        if ($j >= $codecount) {     # if we ran out of tries, error
            my $msg = "All $j subelements exhausted.  Code '$key' from position $i not matched";
            $strict and return carp_error $msg;
            $debug and warn $msg;   # FIXME: this happens too often
        }
    }
    return $self;
    # We're out of parts, so time to check for any outstanding mandatory defs (same kind of loop)
    # This check doesn't work because a subelement can be mandatory in a given optional element.  Context matters.
    while (++$j < $codecount) {
        $codesref->[$j]->{mandatory} and return carp_error
            "Mandatory code '" . $codesref->[$j]->{code} . "' from definition $j missing (all ". $i+1 . " data traversed)";
    }
}

sub _subelement_helper {
    my ($class, $key, $body, $msg) = @_;
    if ($key =~ /^[A-Z]{3}$/) {
        $debug and print STDERR "SEGMENT ($key) detected\n";
        return $class->segment($key => $body);
    } else {
        return $class->subelement({$key => $body}, $msg);
    }
}

# Similar to AUTOLOAD, but by an exact argument, does get and set
# This code should parallel AUTOLOAD tightly.
sub part {
    my $self  = shift;
    my $class = ref($self) or croak "part() object method error: $self is not an object";
    my $name  = shift or return;

    unless (exists $self->{_permitted}->{$name}) {
        if ($self->{def}) {
            if ($name =~ s/^all_(.+)$/$1/i) {   # strip 'all_' prefix
                @_ and croak "part() error: all_$name is read_only, rec'd argument(s): " .  join(', ', @_);
                if ($debug) {
                    warn "part() " . $self->{code} . "/all_$name (from " . scalar(@{$self->{array}}) . " arrayed elements): "
                            . join(' ', map {$_->{code}} @{$self->{array}});
                    $debug > 1 and print STDERR Dumper($self), "\n";
                }
                my $target = $name =~ /^SG\d+$/ ? ($self->{message_code} . "/$name") : $name;
                return grep {$_->{code} and $_->{code} eq $target} @{$self->{array}};    # return array 
            }
            return __PACKAGE__->_deepload_array($self, $name, @_); # not $self->_deepload_array - avoid recursion
        }
        return __PACKAGE__->_deepload($self, $name, @_); # not $self->_deepload - avoid recursion
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

# part_keys gives you values that are always valid as the argument to the same object's part() method
# TODO: mix/match both _permitted and def based?  Maybe.

sub part_keys {
    my $self = shift;
    if ($self->{def}) {
        return map { my $key = $_->{code}; $_->{repeats} > 1 ? "all_$key" : $key } @{$self->{def}};
    }
    return keys %{$self->{_permitted}};
    # my $spec = $self->spec or croak "You must set a spec version (via constructor or spec method) before EDI can know what parts an $self object might have";
}


# Example data:
# 'BGM', {
#     '1004' => '582822',
#     '4343' => 'AC',
#     '1225' => '29',
#     'C002' => {
#        '1001' => '231'
#     }
# }

our $codelist_map;

# Tricky recursive constructor!
sub subelement {
    my $self = shift;
    my $body = shift;
    my $message_code = (@_ and $_[0]) ? shift : '';
    if (! $body) {
        carp "required argument to subelement() empty";
        return;
    }
    unless (ref $body) {
        $debug and carp "subelement() got a regular scalar argument. Returning it ('$body') as subelement";
        return $body;
    }
    ref($body) =~ /^Business::EDI/ and return $body;    # it's already an EDI object, return it

    if (ref($body) eq 'ARRAY') {
        if (scalar(@$body) != 2) {
            carp "Array expected to be psuedohash with 2 elements, or wrapper with 1, instead got " . scalar(@$body);
            return; # [(map {ref($_) ? $self->subelement($_) : $_} @$body)];     # recursion
        } else {
            $body = {$body->[0] => $body->[1]};
        }
    }
    elsif (ref($body) ne 'HASH') {
        carp "argument to subelement() should be ARRAYref or HASHref or Business::EDI subobject, not type '" . ref($body) . "'";
        return;
    }
    $debug and print STDERR "good: we now have a body in class " . (ref($self) || $self) . " with " . scalar(keys %$body) . " key(s): ", join(', ', keys %$body), "\n";
    $codelist_map ||= Business::EDI::CodeList->codemap;
    my $new = {};
    foreach (keys %$body) {
        $debug and print STDERR "subelement building from key '$_'\n";
        my $ref = ref($body->{$_});
        if ($codelist_map->{$_}) {      # If the key is in the codelist map, it's a codelist
            $new->{$_} = $self->codelist($_, $body->{$_})
                or carp "Bad ref ($ref) in body for key $_.  Codelist subelement not created";
        } elsif (/^C\d{3}$/ or /^S\d{3}$/) {
            $new->{$_} = Business::EDI::Composite->new({$_ => $body->{$_}})     # Cxxx and Sxxx codes are for Composite data elements
                or carp "Bad ref ($ref) in body for key $_.  Composite subelement not created";
        } elsif (/^[A-Z]{3}$/) {
            $new->{$_} = $self->segment($_, $body->{$_})                        # ABC codes are for Segments
                or carp "Bad ref ($ref) in body for key $_.  Segment subelement not created";
        } elsif (/^(\S+\/)?(SG\d+)$/) {
            my $sg_spec = $_;
            my $msg     = $1;
            my $sg_tag  = $2;
            $sg_spec =~ s/\/\S+\//\//;      # delete middle tags: ORDRSP/SG25/SG26 => ORSRSP/SG26
            $new->{$sg_spec} = $self->segment_group(($msg ? $sg_spec : "$message_code/$sg_tag"), $body->{$_}, $message_code)   # SGx[x] codes are for Segment Groups
                or carp "Bad ref ($ref) in body for key $_.  Segment_group subelement not created";
        } elsif ($ref eq 'ARRAY') {
            my $count = scalar(@{$body->{$_}});
            $count == 1 or carp "Repeated section '$_' appears $count times.  Only handling first appearance";  # TODO: fix this
            $new->{repeats}->{$_} = -1;
            $new->{$_} = $self->subelement($body->{$_}->[0], $message_code)     # ELSE, break the ref down (recursively)
                or carp "Bad ref ($ref) in body for key $_.  Subelement not created";
        } elsif ($ref) {
            $new->{$_} = $self->subelement($body->{$_}, $message_code)          # ELSE, break the ref down (recursively)
                or carp "Bad ref ($ref) in body for key $_.  Subelement not created";
        } else {
            $new->{$_} = Business::EDI::DataElement->new($_, $body->{$_});      # Otherwise, a terminal (non-ref) data node means it's a DataElement
                  # like Business::EDI::DataElement->new('1225', '582830');
        }
        (scalar(keys %$body) == 1) and return $new->{$_};   # important: if that's our only key/pair, return the object itself, no wrapper.
    }
    return $new;
}


# not really xpath, but xpath-lite-like.  the idea here is to never crash on a valid path, just return undef.
sub xpath {
    my $self  = shift;
    my $path  = shift or return;
    my $class = ref($self) or croak "xpath() object method error: $self is not an object";
    $path eq '/' and return $self;
    $path =~ m#([^-A-z_0-9/\.])# and croak "xpath does not handle '$1' in the path, just decending paths like 'SG27/LIN/1229'";
    $path =~ m#(//)#             and croak "xpath does not handle '$1' in the path, just decending paths like 'SG27/LIN/1229'";
    $path =~ m#^/#               and croak "xpath does not handle leading slashes in the path, just decending relative paths like 'SG27/LIN/1229'";

    my ($front, $back) = split "/", $path, 2;
    defined $front or $front = '';
    defined $back  or $back  = '';
    $debug and print STDERR $class . "->xpath($path)  ==>  ->part($front)->xpath($back);\n";

    if ($front) {
        $back or return $self->part($front);    # no trailing part means we're done!
        my @ret;
        push @ret, $self->part($front) or return;   # front might return multiple hits ('all_SG3', for example)
        return grep {defined $_} map {$_->xpath($back)} @ret;
    }
    croak "xpath does not handle leading slashes in the path, just decending relative paths like 'SG27/LIN/1229'";
}

sub xpath_value {
    my $self = shift;
    my @hits = $self->xpath(@_);
    @hits or return;
    wantarray or return $hits[0]->value;
    return map {$_->value} @hits;
}

our $cgi;
# Write your own CSS
sub html {
    my $self    = shift;
    my $empties = @_ ? shift : 0;
    my $indent  = @_ ? shift : 0;
    my $obtype  = ref $self or return $self;
    my $x = ' ' x $indent;

    my $extra = '';
    $obtype =~ s/^Business::EDI::// or return "$x<div class='edi_error'>$obtype object</div>";
    if ($obtype =~ /::(.*)$/) {
        $extra = " edi_$1";
        $extra  =~ s/::/_/;
        $obtype =~ s/::.*$//;
    }

    my $html = "$x<div class='edi_node edi_$obtype$extra'>";
    my %tophash;
    foreach (qw/code label desc value/) { # get top values, if existing
        $tophash{$_} = $self->$_ if (eval {$self->$_});
    }
    $cgi ||= CGI->new();
    foreach (qw/code label desc value/) { # same order, w/ some fanciness for label (title attribute based on desc)
        defined $tophash{$_} or next;
        my $attrs = {class=>"edi_$_"};
        ($_ eq 'label') and $attrs->{title} = $tophash{desc};
        $html .= "\n$x    " . $cgi->span($attrs, $self->$_);
    }

    my @keys = grep {$_ ne 'label' and $_ ne 'value' and $_ ne 'code' and $_ ne 'desc'} $self->part_keys;   # disclude stuff we already got
    #my @parts = map {$self->part($_)} $self->part_keys;
    my @parts = $self->{array} ? @{$self->{array}} : map {$self->part($_)} @keys;
    $debug and print STDERR $tophash{label}, " has ", scalar(@keys),  " in part_keys: ", join(' ', @keys), "\n";
    # $_->{array} and print "$tophash{label} has ", scalar(@{$_->{array}}), " in array: " . join(' ', map {$_->{code}} @{$_->{array}}), "\n";
    $debug and print STDERR $tophash{label}, " has ", scalar(@parts), " in  'parts' : ", join(' ', map {ref($_) ? $_->{code} : $_} @parts), "\n";
    if (@parts) {
        $html .= "\n$x    <ul>";
        foreach (@parts) {
            (ref $_ and $_->{code}) or next;
            $debug and print STDERR "html(): $tophash{label} => " . $_->{code} . " subcall\n";
            $html .= "\n$x    <li>\n" . $_->html($empties, $indent + 8) . "\n$x    </li>";
        }
        $html .= "\n$x    </ul>"
    }
    return "$html\n$x</div>";
}


1;

# END of Business::EDI
# =======================================================================================

package Business::EDI::Segment_group;
use strict; use warnings;
use Carp;
use base qw/Business::EDI/;
our $VERSION = 0.02;
our $debug;

sub sg_code {
    my $self = shift or return;
    @_ and croak "sg_code is read only (no args)";
    return $self->{sg_code};
}

sub desc {  # build a description on the fly
    my $self = shift or return;
    my $sgcode = $self->sg_code;
    $sgcode =~ s/^SG//i;
    return $self->{message_code} . " Segment Group $sgcode";
}

# Business::EDI::Segment_group gets its own part method to handle meta-mapped SGs INSIDE other SGs,
# but it falls back to the main part method after that.

sub part {
    my $self  = shift;
    my $class = ref($self) or croak("part object method error: $self is not an object");
    my $name  = shift or return;
    my $code  = $self->{message_code} or return $self->carp_error("Message type (code) unset.  Cannot assess metamapping.");
    my $spec  = $self->{spec}         or return $self->carp_error("Message spec (code) unset.  Cannot assess metamapping.");
    my $sg    = $spec->metamap($code, $name);
    my $str_spec = "in spec " . $spec->version;
    if ($sg) {
        $debug and warn "SG Message/field '$code/$name' ==> '$code/all_$sg' via mapping $str_spec";
        if ($sg =~ /\//) {
            my $obj;
            my @chunks = split '/', $sg;
            my $first  = shift @chunks;   
            my $last   = pop   @chunks;   
            $first eq $self->{sg_code} or return $self->carp_error("Mapped target $sg descends from $code/$first $str_spec, not " . $self->{sg_code});
            foreach (@chunks) {
                $obj = $obj ? $obj->SUPER::part("all_$_") : $self->SUPER::part("all_$_");
                $obj or warn "Mapped SG $sg part 'all_$_' not found $str_spec";
                $obj or return;
            }
            return $obj ? $obj->SUPER::part("all_$last", @_) : $self->SUPER::part("all_$last", @_);  # only the last part gets the remaining args
        } else {
            return $self->carp_error("Mapped target $sg is not under " . $self->{code} . " $str_spec");
        }
    } else {
        $debug and warn "Message/field '$code/$name' not mapped $str_spec.  Skipping metamapping";
    }
    return $self->SUPER::part($name, @_);
}


1;

package Business::EDI::Message;
use strict; use warnings;
use Carp;
use base qw/Business::EDI/;
our $VERSION = 0.02;
our $debug;

# Business::EDI::Message gets its own part method to handle meta-mapped SGs,
# but it falls back to the main part method after that.

sub part {
    my $self  = shift;
    my $class = ref($self) or croak("part object method error: $self is not an object");
    my $name  = shift or return;
    my $code  = $self->{message_code} or return carp_error("Message type (code) unset.  Cannot assess metamapping.");
    my $spec  = $self->{spec}         or return carp_error("Message spec (code) unset.  Cannot assess metamapping.");
    my $sg    = $spec->metamap($code, $name);
    if ($sg) {
        $sg =~ s#/#/all_#;    # e.g. SG26/SG30 => SG26/all_SG30
        $debug and warn "Message/field '$code/$name' => '$code/all_$sg' via mapping";
        $name = "all_$sg";    # new target from mapping
    } else {
        $debug and warn "Message/field '$code/$name'  not mapped.  Skipping metamapping";
    }
    return $self->SUPER::part($name, @_);
}

# This is a very high level method.
# We look inside a message body BEFORE we know what it is, and what spec it was written to.
# Second argument is a flag for "string only", in which case we just return the composed version string (e.g. 'D96A')
# otherwise we return a Business::EDI::Message object, or undef on failure.
#
# my $message = Business:EDI::Message->new($body);
# my $version = Business:EDI::Message->new($body, 1);
# 
# Handles ALL valid message types

sub new {
    my $class = shift;
    my $body  = shift     or return $class->carp_error("missing required argument to detect_version()");
    ref($body) eq 'ARRAY' or return $class->carp_error("detect_version_string argument must be ARRAYref, not '" . ref($body) . "'");
    foreach my $node (@$body) {
        my ($tag, $segbody, @xtra) = @$node;
        unless ($tag)     { carp "EDI tag received is empty";      next };
        unless ($segbody) { carp "EDI segment '$tag' has no body"; next };   # IIIIIIiiii, ain't got noboooOOoody!
        if (scalar @xtra) { carp scalar(@xtra) . " unexpected extra elements encountered in detect_version().  Ignoring!";}
        $tag eq 'UNH' or next;

        my $agency  = $segbody->{S009}->{'0051'};   # Thankfully these are true in all syntaxes/specs
        my $pre     = $segbody->{S009}->{'0052'};
        my $release = $segbody->{S009}->{'0054'};
        my $type    = $segbody->{S009}->{'0065'};
        $agency and $agency  eq 'UN' or return $class->carp_error("$tag/S009/0051 does not designate 'UN' as controlling agency");
        $pre    and uc($pre) eq 'D'  or return $class->carp_error("$tag/S009/0052 does not designate 'D' as spec (prefix) version");
        $release                     or return $class->carp_error("$tag/S009/0054 (spec release version) is empty (example value: '96A')");

        @_ and $_[0] and return "$pre$release";     #  "string only"
        my $edi = Business::EDI->new(version => "$pre$release") or
            return $class->carp_error("Spec unrecognized: Failed to create new Business::EDI object with version => '$pre$release'");
        return $edi->message($type, $body);
    }
}

1;

__END__

=head1 NAME

Business::EDI - Top level class for generating U.N. EDI interchange objects and subobjects.

=head1 SYNOPSIS

  use Business::EDI;
  
  my $edi = Business::EDI-new('d09b');      # set the EDI spec version
  my $rtc = $edi->codelist('ResponseTypeCode', $json) or die "Unrecognized code!";
  printf "EDI response type: %s - %s (%s)\n", $rtc->code, $rtc->label, $rtc->value;

  my $msg = Business::EDI::Message->new($ordrsp) or die "Failed Message constructor";
  foreach ($msg->xpath('line_detail/all_LIN') {
      ($_->part(7143) || '') eq 'EN' or next;
      print $_->part(7140)->value, "\n";    # print all the 13-digit (EN) ISBNs
  }


=head1 DESCRIPTION

The focus of functionality is to provide object based access to EDI messages and subelements.
At present, the EDI input processed by Business::EDI objects is JSON from the B<edi4r> ruby library, and
there is no EDI output beyond the perl objects themselves.

=head1 NAMESPACE

When you C<use Business::EDI;> the following package namespaces are also loaded:
    L<Business::EDI::Segment_group>
    L<Business::EDI::Message> 

That's why the example message constructor in SYNOPSIS would succeed without having done C<use Business::EDI::Message;>

=head1 EDI Structure

Everything depends on the spec.  That means you have to have declared a spec version before you can create
or parse a given chunk of data.  The exception is a whole EDI message, because each message declares its 
spec version internally.  

EDI has a hierachical specification defining data.  From top to bottom, it includes:

=over

=item B<Communication> - containing one or more messages (not yet modeled here)

=item B<Message>       - containing segment groups and segments

=item B<Segment Group> - containing segments

=item B<Segment>       - containing composites, codelists and data elements

=item B<Composite>     - containing multiple codelists and/or data elements

=item B<Codelist>      - enumerated value from a spec-defined set

=item B<Data Element>  - unenumerated value

=back

This module handles messages and everything below, but not (yet) communications. 

=head1 CLASS FUNCTIONS

Much more documentation needed here...

=head2 new()

Constructor

=head1 OBJECT METHODS (General)

=head2 value()

Get/set accessor for the value of the field.

=head2 code()

The string code designating this node's type.  The code is what is what the spec uses to refer to the object's definition.
For example, a composite "C504", segment "RFF", data element "7140", etc.

Don't be confused when dealing with CodeList objects.  Calling code() gets you the 4-character code of the CodeList field, NOT
what that CodeList is currently set to.  For that use value().  

=head2 desc()

English description of the element.

=head1 METHODS (for Traversal)

=head2 part_keys()

This method returns strings that can be fed to part() like:
    foreach ($x->part_keys) { something($x->part($_)) }

This is similar to doing:
    foreach (keys %x) { something($x{$_}) }

In this way an object can be exhaustively, recursively parsed without further knowledge of it.

=head2 part($key)

Returns subelement(s) of the object.  The key can reference any subobject allowed by the spec.  If the subobject is repeatable,
then prepending "all_" to the key will return an array of all such subobjects.  This is the safest and most comprehensive approach.
Using part($key) without "all_" to retrieve when there is only one $key subobject will succeed.
Using part($key) without "all_" to retrieve when there are multiple $key subobjects will FAIL.  Since that difference is only dependent on data, 
you should always use "all_" when dealing with a repeatable field (or xpath, see below).

Examples:

    my $qty  = $detail->part('QTY');      # FAILURE PRONE!
    my @qtys = $detail->part('all_QTY');  # OK!


=head2 xpath($path)

$path can traverse multiple depths in representation via one call.  For example:

    $message->xpath('all_SG26/all_QTY/6063')

is like this function foo():

    sub foo {
        my @x;
        for my $sg ($message->part->('all_SG26') {
            for ($sg->part('all_QTY') {
                push @x, $->part('6063');
            }
        }
        return @x;
    }

The xpath version is much nicer!  However this is nowhere near as fully featured as
W3C xpath for XML.  This is more like a multple-depth part().  

Examples:
    my @obj_1154 = $message->xpath('line_detail/SG31/RFF/C506/1154');

=head2 xpath_value($path)

Returns value(s) instead of object(s).

Examples:
    'ORDRSP' eq $ordrsp->xpath_value('UNH/S009/0065') or die "Wrong Message Type!";


=head1 WARNINGS

This code is experimental.  EDI is a big spec with many revisions.

At the lower levels, all data elements, codelists, composites and segments from the most recent spec (D09B) are present.  

=head1 SEE ALSO

 Business::EDI::Spec
 edi4r - http://edi4r.rubyforge.org

=head1 AUTHOR

Joe Atzberger

