package DBass;
use DB_File;
use Fcntl;
use strict;
use vars '$VERSION';
require 5.004;

$VERSION = $VERSION = '0.53';

################################  CONSTANTS  ################################
sub LOCK_SH () { 1 }
sub LOCK_EX () { 2 }
sub LOCK_UN () { 8 }

#########################  ESCAPE MARKUP CHARACTERS  #########################
sub escape (@) {
    my @in = @_;
    for (@in) {
        next unless defined $_;
        s/&/&amp;/gs;
        s/'/&apos;/gs;
        s/</&lt;/gs;
        s/>/&gt;/gs;
        s/"/&quot;/gs;
    }
    wantarray ? @in : shift @in || '';
}

########################  UNESCAPE MARKUP CHARACTERS  ########################
sub unescape (@) {
    my @in = @_;
    for (@in) {
        next unless defined $_;
        s/&amp;/&/gs;
        s/&apos;/'/gs;
        s/&lt;/</gs;
        s/&gt;/>/gs;
        s/&quot;/"/gs;
    }
    wantarray ? @in : shift @in || '';
}

############################  EXPRESS DESTRUCTOR  ############################
sub close {
    my $self = shift;
    &{$self->{'_SUBS'}->{'destroy'}} ($self);
}

##############################  DELETE RECORDS  ##############################
sub delete {
    my $self = shift;
    &{$self->{'_SUBS'}->{'delete'}} ($self, @_);
}

################################  API CHECK  ################################
sub gestalt {
    return unless (@_ > 1 && $_[0] eq '-api' && defined &{$_[1] . '_new'});
    1;
}

################################  READ KEYS  ################################
sub keys {
    my $self = shift;
    &{$self->{'_SUBS'}->{'keys'}} ($self);
}

################################  TAG RECORD  ################################
sub neo_tag ($$) {
    return undef unless @_ > 1;
    my ($root, $in) = @_;
    my $ref = ref $in;
    join '', (
        '<?xml version="1.0" standalone="yes"?><', $root, '>',
        ($ref eq 'ARRAY' ? neo_taglist ($in)
                         : ($ref eq 'HASH' ? neo_taghash ($in)
                                           : neo_tagscalar ($in))),
        '</', $root, '>'
    );
}

sub neo_taghash ($) {
    my $in  = shift;
    my @out = ('<hash>');
    for (sort keys %$in) {
        push @out, '<key>' . escape ($_) . '</key><value>';
        my $ref = ref $in->{$_};
        push @out,
             $ref eq 'ARRAY' ? neo_taglist ($in->{$_})
                             : ($ref eq 'HASH' ? neo_taghash ($in->{$_})
                                               : neo_tagscalar ($in->{$_}));
        push @out, '</value>';
    }
    join '', (@out, '</hash>');
}

sub neo_taglist ($) {
    my $in  = shift;
    my @out = ('<list>');
    for (@$in) {
        push @out, '<value>';
        my $ref = ref $_;
        push @out, $ref eq 'ARRAY' ? neo_taglist ($_)
                                   : ($ref eq 'HASH' ? neo_taghash ($_)
                                                     : neo_tagscalar ($_));
        push @out, '</value>';
    }
    join '', (@out, '</list>');
}

sub neo_tagscalar ($) {
    join '', ('<scalar>', escape (shift), '</scalar>');
}

###############################  UNTAG RECORD  ###############################
{
    my @tagged = ();

    sub neo_untaghash () {
        my %out = ();
        my $key = '';
        while (@tagged) {
            my $in = shift @tagged;
            return \%out if $in eq '<\/hash>';
            if ($in eq '<key>') {
                while (@tagged) {
                    $in = shift @tagged;
                    last if $in eq '</key>';
                    $key = unescape ($in) if length $in;
                }
            } elsif ($in eq '<value>') {
                while (@tagged) {
                    $in = shift @tagged;
                    next unless (length $in && length $key);
                    last if $in eq '</value>';
                    if ($in eq '<hash>') {
                        $out{$key} = &neo_untaghash;
                    } elsif ($in eq '<list>') {
                        $out{$key} = &neo_untaglist;
                    } elsif ($in eq '<scalar>') {
                        $out{$key} = &neo_untagscalar;
                    }
                }
            }
        }
        \%out;
    }

    sub neo_untaglist () {
        my @out = ();
        while (@tagged) {
            my $in = shift @tagged;
            return \@out if $in eq '</list>';
            next if $in ne '<value>';
            while (@tagged) {
                $in = shift @tagged;
                next unless length $in;
                last if $in eq '</value>';
                if ($in eq '<hash>') {
                    push @out, &neo_untaghash;
                } elsif ($in eq '<list>') {
                    push @out, &neo_untaglist;
                } elsif ($in eq '<scalar>') {
                    push @out, &neo_untagscalar;
                }
            }
        }
        \@out;
    }

    sub neo_untagscalar () {
        my $out = '';
        while (@tagged) {
            my $in = shift @tagged;
            return $out if $in eq '</scalar>';
            $out .= unescape ($in) if length $in;
        }
        $out;
    }

    sub neo_untag ($$) {
        my $root = shift;
        @tagged = split /(<.+?>)/, shift;
        while (@tagged) {
            my $in = shift @tagged;
            if ($in eq '<?xml version="1.0" standalone="yes"?>') {
                while (@tagged) {
                    $in = shift @tagged;
                    if ($in =~ /^<$root>/) {
                        while (@tagged) {
                            $in = shift @tagged;
                            if ($in eq '<hash>') {
                                return neo_untaghash;
                            } elsif ($in eq '<list>') {
                                return neo_untaglist;
                            } elsif ($in eq '<scalar>') {
                                return neo_untagscalar;
                            }
                        }
                    }
                }
            }
        }
    }
}

#################################  NEO READ  #################################
sub neo_read {
    my $self = shift;
    my %argv = @_;
    my $ref;
    for (defined $argv{'-keys'} && defined $argv{'-root'}
            ? (($ref = ref $argv{'-keys'}) eq 'ARRAY'
                ? @{$argv{'-keys'}}
                : ($ref eq 'HASH' ? keys %{$argv{'-keys'}} : $argv{'-keys'}))
            : (defined $self->{'_HASHREF'}
                ? keys %{$self->{'_HASHREF'}}
                : keys %{$self->{'_UNTAGGED'}})) {
        next if defined $self->{'_UNTAGGED'}->{$_};
        $self->{'_UNTAGGED'}->{$_} =
            neo_untag $argv{'-root'}, $self->{'_HASHREF'}->{$_}
            if (defined $self->{'_HASHREF'} &&
                defined $self->{'_HASHREF'}->{$_});
    }
    $self->{'_UNTAGGED'};
}

################################  NEO WRITE  ################################
sub neo_write {
    my $self = shift;
    return 1 unless defined $self->{'_OBJ'};
    die unless $self->{'_MODE'} =~ /[+>]/;
    my %argv = @_;
    die unless defined $argv{'-hash'} && defined $argv{'-root'};
    for (keys %{$argv{'-hash'}}) {
        next unless defined $argv{'-hash'}->{$_};
        $self->{'_HASHREF'}->{$_} =
            neo_tag $argv{'-root'}, $argv{'-hash'}->{$_};
        $self->{'_UNTAGGED'}->{$_} = $argv{'-hash'}->{$_};
    }
    $self->{'_OBJ'}->sync;
}

###############################  CONSTRUCTOR  ###############################
sub new {
    my $class = shift;
    my %argv  = ('-api' => 'neo', @_);
    my $api   = $argv{'-api'};
    my %subs  = (
        'neo' => {
            'delete'  => \&xeen_delete,
            'destroy' => \&xeen_destroy,
            'keys'    => \&xeen_keys,
            'new'     => \&xeen_new,
            'read'    => \&neo_read,
            'write'   => \&neo_write
        },
        'xeen' => {
            'delete'  => \&xeen_delete,
            'destroy' => \&xeen_destroy,
            'keys'    => \&xeen_keys,
            'new'     => \&xeen_new,
            'read'    => \&xeen_read,
            'write'   => \&xeen_write
        }
    );
    die unless defined $subs{$api};
    my $self = {};
    $class = ref $class || $class;
    bless ($self, $class);
    $self->{'_SUBS'} = $subs{$api};
    &{$self->{'_SUBS'}->{'new'}} ($self, %argv);
    $self;
}

###############################  READ RECORDS  ###############################
sub read {
    my $self = shift;
    &{$self->{'_SUBS'}->{'read'}} ($self, @_);
}

##############################  WRITE RECORDS  ##############################
sub write {
    my $self = shift;
    &{$self->{'_SUBS'}->{'write'}} ($self, @_);
}

################################  TAG RECORD  ################################
sub xeen_tag {
    my $root = shift;
    return undef unless @_;
    my $out = xeen_taghash (@_);
    $root = escape $root;
    '<?xml version="1.0" standalone="yes"?><' .
        $root . '>' . $out . '</' . $root . '>';
}

sub xeen_taghash {
    my $in = shift;
    my $out = '';
    for (sort keys %$in) {
        my $key = escape $_;
        my $ref = ref $in->{$_};
        if ($ref eq 'ARRAY') {
            $out .= xeen_taglist ($key, \@{$in->{$_}});
        } elsif ($ref eq 'HASH') {
            $out .= join '', (
                '<', $key, '>', xeen_taghash ($in->{$_}), '</', $key, '>'
            );
        } elsif (defined $in->{$_}) {
            $out .= join '', (
                '<', $key, '>', escape ($in->{$_}),  '</', $key, '>'
            );
        }
    }
    $out;
}

sub xeen_taglist {
    my ($key, $in) = @_;
    my $top = '<'  . $key . '>';
    my $end = '</' . $key . '>';
    my $out = '';
    for (@$in) {
        my $ref = ref $_;
        if ($ref eq 'HASH') {
            $out .= join '', ($top, xeen_taghash ($_), $end);
        } elsif (defined $_) {
            $out .= join '', ($top, escape ($_), $end);
        }
    }
    $out;
}

###############################  UNTAG RECORD  ###############################
{
    my @tagged = ();

    sub xeen_untag ($$) {
        my $root = escape shift;
        @tagged = split /(<.+?>)/, shift;
        while (@tagged) {
            my $in = shift @tagged;
            if ($in eq '<?xml version="1.0" standalone="yes"?>') {
                while (@tagged) {
                    $in = shift @tagged;
                    if ($in =~ /^<$root>/) {
                        my $untagged = xeen_untaghash ($root);
                        return $untagged->{$root};
                    }
                }
            }
        }
    }

    sub xeen_untaghash {
        my $root = shift;
        my %out = ();
        while (@tagged) {
            my $in = shift @tagged;
            next unless $in;
            return \%out if $in =~ /^<\/$root>/;
            my $unroot = unescape $root;
            if ($in =~ /^<(.+?)>/) {
                my $tag = $1;
                my $untagged = xeen_untaghash ($tag);
                $tag = unescape $tag;
                if (defined $out{$unroot} && defined $out{$unroot}{$tag}) {
                    if (ref $out{$unroot}{$tag} eq 'ARRAY') {
                        push @{$out{$unroot}{$tag}}, $untagged->{$tag};
                        next;
                    }
                    my $val = $out{$unroot}{$tag};
                    undef $out{$unroot}{$tag};
                    @{$out{$unroot}{$tag}} = ($val, $untagged->{$tag});
                    next;
                }
                $out{$unroot}{$tag} = $untagged->{$tag};
                next;
            }
            $out{$unroot} = unescape $in;
        }
    }
}

###############################  XEEN DELETE  ###############################
sub xeen_delete {
    my $self = shift;
    return 1 unless defined $self->{'_OBJ'};
    die unless $self->{'_MODE'} =~ /[+>]/;
    my %argv = @_;
    if (defined $argv{'-keys'}) {
        my $ref = ref $argv{'-keys'};
        if ($ref eq 'ARRAY') {
            for (@{$argv{'-keys'}}) {
                delete $self->{'_HASHREF'}->{$_}
                    if exists $self->{'_HASHREF'}->{$_};
                delete $self->{'_UNTAGGED'}->{$_}
                    if exists $self->{'_UNTAGGED'}->{$_};
            }
        } elsif ($ref eq 'HASH') {
            for (keys %{$argv{'-keys'}}) {
                delete $self->{'_HASHREF'}->{$_}
                    if exists $self->{'_HASHREF'}->{$_};
                delete $self->{'_UNTAGGED'}->{$_}
                    if exists $self->{'_UNTAGGED'}->{$_};
            }
        } else {
            my $key = $argv{'-keys'};
            delete $self->{'_HASHREF'}->{$key}
                if exists $self->{'_HASHREF'}->{$key};
            delete $self->{'_UNTAGGED'}->{$key}
                if exists $self->{'_UNTAGGED'}->{$key};
        }
    } else {
        $self->{'_HASHREF'}  = {};
        $self->{'_UNTAGGED'} = {};
    }
    $self->{'_OBJ'}->sync;
}

#############################  XEEN DESTRUCTOR  #############################
sub xeen_destroy {
    my $self = shift;
    return 1 unless defined $self->{'_OBJ'};
    undef $self->{'_OBJ'};
    untie %$self->{'_HASHREF'};
    if ($^O eq 'MacOS' || $^O eq 'MacPerl') {
        chmod 0666, $self->{'_LOCK'};
    } else {
        flock $self->{'_FH'}, LOCK_UN;
        CORE::close $self->{'_FH'};
    }
}

################################  XEEN KEYS  ################################
sub xeen_keys {
    my $self = shift;
    keys %{$self->{'_HASHREF'}};
}

#############################  XEEN CONSTRUCTOR  #############################
sub xeen_new {
    my $self = shift;
    my %argv = ('-mode' => 0644, @_);
    die unless $argv{'-file'};
    ($self->{'_FILE'} = $argv{'-file'}) =~ s/^([+<>]+)//;
    $self->{'_MODE'} = $1 || '';
    $self->{'_LOCK'} = $argv{'-lock'};
    $self->{'_UNTAGGED'} = {};
    if ($^O eq 'MacOS' || $^O eq 'MacPerl') {
        chmod 0444, $self->{'_LOCK'};
    } else {
        if ($self->{'_MODE'} =~ /[+>]/) {
            open FH, '>>' . $self->{'_LOCK'} or die $!;
            unless (flock FH, LOCK_EX) {
                CORE::close FH;
                die;
            }
        } else {
            open FH, $self->{'_LOCK'} or die $!;
            unless (flock FH, LOCK_SH) {
                CORE::close FH;
                die;
            }
        }
        $self->{'_FH'} = *FH;
    }
    die unless
        $self->{'_OBJ'} = tie %{$self->{'_HASHREF'}}, 'DB_File',
            $self->{'_FILE'}, O_CREAT | O_RDWR, $argv{'-mode'};
}

################################  XEEN READ  ################################
sub xeen_read {
    my $self = shift;
    my %argv = @_;
    my $ref;
    for (defined $argv{'-keys'} && defined $argv{'-root'}
            ? (($ref = ref $argv{'-keys'}) eq 'ARRAY'
                ? @{$argv{'-keys'}}
                : ($ref eq 'HASH' ? keys %{$argv{'-keys'}} : $argv{'-keys'}))
            : (defined $self->{'_HASHREF'}
                ? keys %{$self->{'_HASHREF'}}
                : keys %{$self->{'_UNTAGGED'}})) {
        next if defined $self->{'_UNTAGGED'}->{$_};
        $self->{'_UNTAGGED'}->{$_} =
            xeen_untag $argv{'-root'}, $self->{'_HASHREF'}->{$_}
            if (defined $self->{'_HASHREF'} &&
                defined $self->{'_HASHREF'}->{$_});
    }
    $self->{'_UNTAGGED'};
}

################################  XEEN WRITE  ################################
sub xeen_write {
    my $self = shift;
    return 1 unless defined $self->{'_OBJ'};
    die unless $self->{'_MODE'} =~ /[+>]/;
    my %argv = @_;
    die unless defined $argv{'-hash'} && defined $argv{'-root'};
    for (keys %{$argv{'-hash'}}) {
        next unless defined $argv{'-hash'}->{$_};
        $self->{'_HASHREF'}->{$_} =
            xeen_tag $argv{'-root'}, \%{$argv{'-hash'}->{$_}};
        $self->{'_UNTAGGED'}->{$_} = \%{$argv{'-hash'}->{$_}};
    }
    $self->{'_OBJ'}->sync;
}

################################  DESTRUCTOR  ################################
sub DESTROY {
    my $self = shift;
    &{$self->{'_SUBS'}->{'destroy'}} ($self);
}

1;

__END__

=pod

=head1 NAME

C<DBass> - DBM with associative arrays, file locking and XML records

=head1 SYNOPSIS

    use DBass;

    die unless DBass::gestalt (-api => 'xeen');
    my $db = DBass->new (
        -api  => 'neo',
        -file => '+<file.dbm',
        -lock => 'file.lock',
        -mode => 0644
    );

=head1 DESCRIPTION

This module provides methods to read, write and delete associative arrays in
DBM files, with file locking and XML records.

It uses a named argument C<-api> for class methods C<new> and C<gestalt> to
try to prevent later versions of the module from breaking preexisting APIs.

=head1 METHODS

=over 4

=item C<gestalt>

This method checks for the existence of an API:

    die 'no API neo' unless DBass::gestalt (-api => 'neo');

C<-api> is the calling API to check for.  One should use this method only for
development or testing, and not in frequently used applications.

=item C<new>

This method creates a new DBass object, and should be the first one called:

    my $db = DBass->new (
        '-api'  => 'neo',
        '-file' => '+<file.dbm',
        '-lock' => 'file.lock',
        '-mode' => 0644
    );

C<-api> is the calling API to use.  C<-file> is the read/write mode (default
is read-only) and DBM filename.  C<-lock> is the lock filename.  C<-mode> is
the file permissions mode of the DBM file.

If the DBM file is opened for read-only access, the lock file must preexist,
but can be empty.  In MacOS, one can create an empty file with SimpleText.  In
*nix, one can create an empty file with C<touch>:

    touch file.lock

This version of the module has APIs C<xeen> and X<neo>.  The C<xeen> API is
deprecated and provided for backward compatibility only, and the C<neo> API
should be used when possible.

=item C<close>

This method releases various resources in the DBass object, to allow other
processes to access the DBM file:

    $db->close;

Normally this method should not be used, as it renders the object useless for
the remainder of the program execution (and is automatically called when the
object is destroyed).

=item C<delete>

This method deletes records from the DBM file:

    $db->delete ('-keys' => \@keys);
    $db->delete ('-keys' => \%keys);
    $db->delete ('-keys' =>  $key );

B<Be careful.>  It can also delete all records:

    $db->delete;

=item C<keys>

This method returns record keys:

    my @keys = $db->keys;

=item C<read>

This method returns a hash reference pointing to records in the DBM file:

    my $smallerhashref = $db->read ('-keys' => \@keys, '-root' => $root);
    my $smallerhashref = $db->read ('-keys' => \%keys, '-root' => $root);
    my $smallhashref   = $db->read ('-keys' =>  $keys, '-root' => $root);
    my $entirehashref  = $db->read ('-root' =>  $root);

C<-keys> are the keys to match against.  C<-root> is the XML root tag name
used in storing the records.

=item C<write>

This method writes key-value pairs to the DBM file:

    $db->write (-hash => \%hash, -root => $root);

C<-hash> is the hash reference pointing to the key-value pairs (records).
C<-root> is the XML root tag name to use in storing the records.

=back

=head1 KNOWN ISSUES

The C<xeen> API is deprecated and provided for backward compatibility only,
and the C<neo> API should be used when possible.  The main reason for the API
name change is that the C<neo> record format is significantly different from
that of C<xeen>.

On platforms other than MacOS, *nix or Windows NT, C<flock> will probably
cause the module to crash and burn.

The module should be pronounced C</di'bas/>.

The C<xeen> API is not named after the IBM alphaWorks C<Xeena> XML editor.

=head1 CHANGES

    0.53  2000.01.11  fixed Makefile.PL (oops!)

    0.52  1999.10.30  added check for _OBJ
                      added check for _HASHREF
                      fixed neo_read handling of _UNTAGGED
                      fixed neo_read to check for _HASHREF
                      fixed neo_write to check for _OBJ
                      fixed xeen_delete to check for _OBJ
                      fixed xeen_destroy to check for _OBJ
                      fixed xeen_new die preparation
                      fixed xeen_new to include _UNTAGGED
                      fixed xeen_read handling of _UNTAGGED
                      fixed xeen_read to check for _HASHREF
                      fixed xeen_write to check for _OBJ

    0.51  1999.10.26  fixed gestalt for wantarray
                      fixed neo_read to accept hash references as -keys
                      fixed xeen_delete to accept hash references as -keys
                      fixed xeen_read to accept hash references as -keys

    0.50  1999.10.06  added neo API (valid XML tags and lists of lists)

    0.40  1999.09.20  fixed DBM file locking bug in xeen_destroy
                      fixed DBM file locking bug in xeen_new
                      fixed xeen_delete to accept scalars as -keys
                      fixed xeen_read to accept scalars as -keys

=head1 AUTHOR

Copyright 1999, 2000 Nguon Hao Ching (C<spiderboy@spiderboy.net>).

=head1 CREDITS

Thanks to Tom Christiansen for Perl Cookbook recipe 14.5.

Thanks to Mark-Jason Dominus for the Perl Monger tutorial on file locking.

Thanks to David Harris and Paul Marquess for the recipe bug report.

Thanks to Chris Nandor for C<perlport>.

Thanks to James Wismer for feedback on the initial, unreleased version.

Thanks to Jay Trolley for her patience and understanding.

Thanks to xeenie for everything else.

=cut
