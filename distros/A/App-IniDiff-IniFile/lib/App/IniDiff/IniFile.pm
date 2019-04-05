package App::IniDiff::IniFile;

use 5.006;

use strict;
use Carp;

=head1 NAME

App::IniDiff::IniFile - perl module to diff and patch .ini files

=head1 VERSION

Version 0.19

=cut

use vars qw($VERSION);
$VERSION = '0.19';

=head1 DESCRIPTION

IniFile.pm - perl module to diff and patch .ini files

=head1 SYNOPSIS

This file contains the following:

=over 4

=item * package App::IniDiff::IniFile;

=item * package App::IniDiff::IniFile::Field;

=item * package App::IniDiff::IniFile::Key;

=item * package App::IniDiff::IniFile::Filter;

=back

Creates the following data structure:

    {
        'nextOrderId' => some-number,
        'keys' => {
          {
            'name' => "...",
            'orderId' => some number,
            'fields' => [
                {
                    'name' => "..."
                    'value' => "...",
                    'deleted' => 0 or 1,
                    'annotation' => "...",
                },
                ...
                ],
            'deleted' => 0 or 1,
            'annotation' => "...",
            },
            ...
        },
    }

=over 4

=item * 'orderId' is used to preserve the order in which keys appear in a file.

=item * 'annotation' is used to decorate inidiff output.

=item * 'deleted' is used when generating, writing, reading, and applying patch files.

=back

Some terms used differ from what is normally used in WinINI file-speak

=over 4

=item * 'key' is INI 'section'

=item * 'field' is INI 'entry'

=item * 'field name' is INI 'key'

=item * 'field value' is INI 'value'

=back

=cut

use vars qw(&new &write &findKey &keys &removekey &addKey);

# added eol to support old end of line \r\n
use vars qw($errorString $eol $commentchars);    

{

    package App::IniDiff::IniFile::Field;

    use strict;
    use Carp;

    use vars qw(&new &name &canonName &value &deleted &annotation
      &setFrom &write &canonicalize );
    use vars qw($eol);

    # end of line character - eol
    $eol = "\n";

    sub new
    {
        my $proto = shift;
        confess "new App::IniDiff::IniFile::Field takes 4 arguments" if @_ != 4;
        my ($name, $value, $del, $annotation) = @_;

        my $field = {
            'name'       => $name,
            'canonName'  => canonicalize($name),
            'value'      => $value,
            'deleted'    => $del,
            'annotation' => $annotation,
        };

        bless $field, (ref($proto) || $proto);
        return $field;
    }

    sub name {
        my $field = shift;
        if (@_) { $field->{'name'} = shift }
        return $field->{'name'};
    }

    sub canonName {
        my $field = shift;
        if (@_) { $field->{'canonName'} = shift }
        return $field->{'canonName'};
    }

    sub value {
        my $field = shift;
        if (@_) { $field->{'value'} = shift }
        return $field->{'value'};
    }

    sub deleted {
        my $field = shift;
        if (@_) { $field->{'deleted'} = shift }
        return $field->{'deleted'};
    }

    sub annotation {
        my $field = shift;
        if (@_) { $field->{'annotation'} = shift }
        return $field->{'annotation'};
    }

    sub setFrom
    {
        my $field = shift;
        my $from  = shift;
        $field->name($from->name);
        $field->value($from->value);
        $field->deleted($from->deleted);
        $field->annotation($from->annotation);
        return $field;
    }

    sub canonicalize
    {

        # Called as object method
        if (@_ > 0 && ref $_[0]) {
            return ${$_[0]}->canonName if (@_ == 1);
        }

        # Called as object or class method with argument
        if (@_ == 2) {
            shift;
        }
        elsif (@_ != 1) {
            confess "wrong number of args" if (@_ != 0);
        }
        my $name = $_[0];
        $name =~ tr/A-Z/a-z/;
        return $name;
    }

    sub write
    {
        my ($field, $fileHandle) = @_;

        print $fileHandle "; ", $field->annotation, $eol
          if defined $field->annotation;
        print $fileHandle $field->name;
        if ($field->deleted) {
            print $fileHandle "-";
        }
        elsif (defined $field->value) {
            print $fileHandle "=", $field->value;
        }
        print $fileHandle $eol;
    }
}    # End package App::IniDiff::IniFile::Field;

{

    package App::IniDiff::IniFile::Key;

    use strict;
    use Carp;
    use IO::File;

    use vars qw(&new &name &canonName &orderId &deleted &annotation &fields
      &canonicalize &findField &addField &appendField &removeField
      &write
    );
    use vars qw($eol);

    # end of line character - eol
    $eol = "\n";

    sub new
    {
        my $proto = shift;
        confess "new App::IniDiff::IniFile::Key takes 3 arguments" if @_ != 3;
        my ($name, $del, $annotation) = @_;

        my $key = {
            'name'       => $name,
            'canonName'  => canonicalize($name),
            'orderId'    => undef,
            'deleted'    => $del,
            'annotation' => $annotation,
            'fields'     => [],
        };

        bless $key, (ref($proto) || $proto);
        return $key;
    }

    sub name {
        my $key = shift;

        # Do not change canonName (see kludge in App::IniDiff::IniFile::new regarding patches)
        if (@_) { $key->{'name'} = shift }
        return $key->{'name'};
    }

    sub canonName {
        my $key = shift;
        if (@_) { $key->{'canonName'} = shift }
        return $key->{'canonName'};
    }

    sub orderId {
        my $key = shift;
        if (@_) { $key->{'orderId'} = shift }
        return $key->{'orderId'};
    }

    sub deleted {
        my $key = shift;
        if (@_) { $key->{'deleted'} = shift }
        return $key->{'deleted'};
    }

    sub annotation {
        my $key = shift;
        if (@_) { $key->{'annotation'} = shift }
        return $key->{'annotation'};
    }

    sub fields {
        my $key = shift;
        confess "too many args" if @_ > 0;
        return $key->{'fields'};
    }

    sub canonicalize
    {

        # Called as object method
        if (@_ > 0 && ref $_[0]) {
            return ${$_[0]}->canonName if (@_ == 1);
        }

        # Called as object or class method with argument
        if (@_ == 2) {
            shift;
        }
        elsif (@_ != 1) {
            confess "wrong number of args" if (@_ != 0);
        }
        my $name = $_[0];
        $name =~ tr/A-Z/a-z/;
        return $name;
    }

    # Note: only finds first field...
    sub findField
    {
        my ($key, $fieldName) = @_;
        $fieldName = App::IniDiff::IniFile::Field->canonicalize($fieldName);

        my ($field);
        foreach $field (@{$key->fields}) {
            return $field if ($field->canonName eq $fieldName);
        }
        return undef;
    }

    sub addField
    {
        my $key   = shift;
        my $field = shift;

        my $xfield = $key->findField($field->name);
        if (defined $xfield) {
            $xfield->setFrom($field);
            return $xfield;
        }
        return $key->appendField($field);
    }

    sub appendField
    {
        my $key   = shift;
        my $field = shift;

        push(@{$key->fields}, $field);
        return $field;
    }

    #
    # Remove a field, either by name or by reference
    #
    sub removeField
    {
        my $found = 0;
        my ($key, $arg) = @_;

        if (ref $arg) {
            my $fieldToast = $arg;
            for (my $i = 0 ; $i < @{$key->fields} ; $i++) {
                my $field = ${$key->fields}[$i];
                if ($field eq $fieldToast) {
                    splice(@{$key->fields}, $i, 1);
                    $i--;
                    $found++;
                }
            }
        }
        else {
            my $fieldName = App::IniDiff::IniFile::Field->canonicalize($arg);
            for (my $i = 0 ; $i < @{$key->fields} ; $i++) {
                my $field = ${$key->fields}[$i];
                if ($field->canonName eq $fieldName) {
                    splice(@{$key->fields}, $i, 1);
                    $i--;
                    $found++;
                }
            }
        }
        return $found;
    }

    sub write
    {
        my ($key, $fileHandle) = @_;
        my ($del) = $key->deleted ? '-' : '';

        print $fileHandle "; ", $key->annotation, $eol
          if defined $key->annotation;
        print $fileHandle "[", $key->name, "]", $del, $eol;
        if (!$key->deleted) {
            my $field;
            foreach $field (@{$key->fields}) {
                $field->write($fileHandle);
            }
        }
        print $fileHandle $eol;
    }
}    # End package App::IniDiff::IniFile::Key;

# $IniFile package Globals
$errorString = undef;

# end of line character - eol
$eol          = "\n";
$commentchars = ';#';    # Allow DOS and Unix style comment.

sub new
{
    my $proto = shift;

    my $ini = {

        # Used to generate monotonically increasing key ids - used
        # to reserve order of ini file.
        'nextOrderId' => 0,
        'keys'        => {},
    };

    bless $ini, (ref($proto) || $proto);

    return $ini if (@_ == 0);
    confess "new called with too many arguments" if (@_ > 4);

    my ($fileHandle, $isPatch, $addM, $stripComments) =
      @_;    # Patches: allow duplicate key names
    my ($key);
    my $ok = 1;

    $isPatch = 0 if !defined $isPatch;
    $addM    = 0 if !defined $addM;      # add ^M if pre-NT
    $stripComments = 0 if ! defined $stripComments;  
    # strip out trailing inline comments having semicolon
    # comment out stripComments if isPatch 
    # - this may be a problem 
    # - leave them in unless specifically asked
    # $stripComments = 1 if $isPatch; # always strip out comments from patches
    if ($addM == 1) {
        $eol = "\r\n";

        # set the children's eol members to this value as well ... 
        # not using set() methods - oh dear
        $App::IniDiff::IniFile::Key::eol   = "\r\n";
        $App::IniDiff::IniFile::Field::eol = "\r\n";
    }

    while (<$fileHandle>) {
        chomp;

        #
        # Strip comments - not in key names ([...]) and not in strings..
        #
        # if a [key] section
        if (/^\s*(\[[^]]+])(.*)$/) {
            my ($key, $rest) = ($1, $2);

            # do care if it strips comments after [key] section
            if ($stripComments) {
                $rest =~ s/[$commentchars].*//;
            }
            $_ = $key . $rest;
        }

        # not a comment starting with ; and has a " in it
        elsif (!/^\s*[$commentchars]/ && /"/) {

            # Slow, but perl won't go exponential...
            my $line = '';

            # walk through non comments and matched quoted strings 
            # from left to right
            # until we hit a comment character or a non matched quote
            while (/^([^"$commentchars]*"[^"]*")(.*)/) {
                $line .= $1;
                $_ = $2;
            }

            # Some (burnt) ini files have unmatched quotes... rather
            # than toast these, we assume they have no comments.
            if (!/"/) {

                # do not strip comments unless requested
                if ($stripComments) {
                    s/[$commentchars].*//;
                }
            }
            $_ = $line . $_;
        }
        elsif ($stripComments) {
            s/[$commentchars].*//;
        }
        s/\s*$//;    # remove trailing space includes \r...
         # not skipping blank lines at this point results in errors when diffing
        next if /^$/;    # skip blank lines
        if (/^\s*\[([^]]+)](-?)$/) {
            my ($name, $del) = ($1, $2);
            if ($isPatch) {

                # Patches are a bit strange as there can be duplicate
                # key names - to deal with this, the canonName (hash index)
                # is a generated (unique) thing and we fix up the real name
                # after the key is created.
                $key = $ini->addKey(
                    new App::IniDiff::IniFile::Key(
                        "[$ini->{'nextOrderId'}]",
                        $del eq '-', undef));
                $key->name($name);
            }
            else {
                if ($del eq '-') {
                    $errorString = "$.: non-patch file has deleted key";
                    $ok          = 0;
                    last;
                }
                if ($ini->findKey($name)) {
                    $errorString = "$.: duplicate key: $name";
                    $ok          = 0;
                    last;
                }
                $key =
                  $ini->addKey(new App::IniDiff::IniFile::Key($name, $del eq '-', undef));
            }
            next;
        }

        # passed through, this is not a key, so it is something else
        my ($name, $value);

        # fix quotes
        if (/"/) {

            # Slow, but perl won't go exponential...
            my $line = '';

            # cycle through matched pairs of quotes in LHS $name
            # accepts = between pair of quotes in LHS
            while (/^([^"=]*"[^"]*")(.*)$/) {
                $line .= $1;
                $_ = $2;
            }

            # no remaining quotes in LHS
            # allows unmatched quote in RHS
            if (/^([^"]*)=(.*)$/) {
                $name  = $line . $1;
                $value = $2;
            }
            elsif (/"/) {

                # Wonder if this will be a problem...
                $errorString = "$.: unmatched quote (no preceeding =)";
                $ok          = 0;

                # quits here ... maybe we shouldn't quit parsing
                last;
            }
            else {
                $name  = $line . $_;
                $value = undef;
            }
        }
        elsif (/^([^=]+)=(.*)$/) {
            $name  = $1;
            $value = $2;
        }
        else {
            $name  = $_;
            $value = undef;
        }
        my $del = 0;
        if (!defined $value && $name =~ /-$/) {
            if (!$isPatch) {
                $errorString = "$.: non-patch file has deleted field";
                $ok          = 0;
                last;
            }
            $del = 1;
            chop $name;
        }
        if (!defined $key) {
            $errorString = "$.: field outside of key\n";
            $ok          = 0;
            last;
        }
        if ($key->deleted) {
            $errorString = "$.: deleted key has field\n";
            $ok          = 0;
            last;
        }

        # when a comment precedes a new key (section), 
        # it gets stuck with the previous one
        # because the blank line at the end of a key section 
        # must get eaten for inidiff to work
        $key->appendField(new App::IniDiff::IniFile::Field($name, $value, $del, undef));
    }
    return undef if !$ok;
    return $ini;
}

sub write
{
    my ($ini, $fileHandle) = @_;
    my ($key);

    foreach $key (@{$ini->keys}) {
        $key->write($fileHandle);
    }
}

sub findKey
{
    my ($ini, $keyName) = @_;
    return $ini->{'keys'}->{App::IniDiff::IniFile::Key->canonicalize($keyName)};
}

sub keys
{
    my ($ini) = @_;

    return [
        sort { $a->orderId <=> $b->orderId }
          values(%{$ini->{'keys'}}) ];
}

#
# Remove a key, either by name or by reference
#
sub removeKey
{
    my ($ini, $arg) = @_;

    if (ref $arg) {
        my $keyToast = $arg;
        my ($name, $key);
        while (($name, $key) = each %{$ini->{'keys'}}) {
            if ($key eq $keyToast) {
                delete $ini->{'keys'}->{$name};
            }
        }
    }
    else {
        my $keyName = $arg;
        return delete $ini->{'keys'}->{App::IniDiff::IniFile::Key->canonicalize($keyName)};
    }
}

sub addKey
{
    my ($ini, $key) = @_;

    $ini->{'keys'}->{$key->canonName} = $key;
    $key->orderId($ini->{'nextOrderId'}++);
    return $key;
}

{

    package App::IniDiff::IniFile::Filter;

    use strict;
    use Carp;
    use IO::File;

    use vars qw(&new &readConf &filter &export);
    use vars qw($errorString);

    sub new
    {
        my $proto = shift;
        confess "new App::IniDiff::IniFile::Filter takes no arguments" if @_ != 0;

        my $field = {
            'keyFilters' => []
        };

        bless $field, (ref($proto) || $proto);
        return $field;
    }

    sub readConf
    {
        my ($filter, $file) = @_;

        my $in = new IO::File $file, "r";
        if (!defined $in) {
            $errorString = "can't open $file - $!";
            return 0;
        }

        my ($keyActions)   = undef;
        my ($entryActions) = undef;

        while (<$in>) {
            next if (/^\s*(#|$)/);

            # Trim whitespace
            s/^\s+//;
            s/\s+$//;

            # include another filter file?
            if (/^\s*include\s+"([^"]*)"\s*$/) {
                my ($ifile) = $1;

                # End the previous key (with error checking)
                # added {} around keyActions
                if (defined $keyActions && !@{$keyActions}) {    
                    $errorString = "$file:$.: previous key has no actions";
                    $in->close;
                    return 0;
                }
                # added {} around entryActions
                elsif (defined $entryActions && !@{$entryActions}) {
                    $errorString =
                      "$file:$.: previous name/value pattern has no actions";
                    $in->close;
                    return 0;
                }
                $keyActions = $entryActions = undef;

                # If not an absolute path, try relative to this file first.
                my ($mypath) = $file;
                $mypath =~ s:/+[^/]*$::;
                if ($ifile !~ /^\//
                    && $mypath ne ''
                    && $mypath ne $file
                    && -e $mypath."/".$ifile)
                {
                    return 0 if (!$filter->readConf($mypath."/".$ifile));
                }
                else {
                    return 0 if (!$filter->readConf($ifile));
                }
                next;
            }

            # A new key?
            if (/^\[(.+)](|\s*-)$/) {
                my ($keyPat, $isDel) = ($1, $2 eq '' ? 0 : 1);

                if (defined $keyActions && !@{$keyActions}) {    # added {}
                    $errorString = "$file:$.: previous key has no actions";
                    $in->close;
                    return 0;
                }
                elsif (defined $entryActions && !@{$entryActions}) { # added {}
                    $errorString =
                      "$file:$.: previous name/value pattern has no actions";
                    $in->close;
                    return 0;
                }

                push(
                    @{$filter->{'keyFilters'}},
                    {
                        'keyPat'     => $1,
                        'deleteAll'  => $isDel,
                        'keyActions' => []
                    });

                # ${$filter} is not an array
                # $keyActions = $isDel ? undef : 
                #                 ${$filter}[$#$filter]->{'keyActions'};
                my @filterHashes = @{$filter->{'keyFilters'}};
                my $numHashes    = $#filterHashes;
                $keyActions =
                  $isDel ? undef : $filterHashes[$numHashes]->{'keyActions'};
                next;
            }

            # A new entry match operator?
            if (/^\s*(name|value)\s+(\S.*)$/) {
                my ($matchOn, $matchPat) = ($1, $2);
                if (!defined $keyActions) {
                    $errorString =
                      "$file:$.: name/value pattern found outside key";
                    $in->close;
                    return 0;
                }
                if (defined $entryActions && !@{$entryActions}) { # added {}
                    $errorString =
                      "$file:$.: previous name/value pattern has no actions";
                    $in->close;
                    return 0;
                }
                $entryActions = [];

                # added {} to keyActions
                push(
                    @{$keyActions},
                    {   'matchOn'      => $matchOn,
                        'matchPat'     => $matchPat,
                        'entryActions' => $entryActions,
                    });
                next;
            }

            # A entry substitution
            if (/^\s*subst\s+(name|value)\s+(\S.*)$/) {
                my ($action, $subst) = ($1, $2);
                if (!defined $keyActions) {
                    $errorString = "$file:$.: substitution found outside key";
                    $in->close;
                    return 0;
                }
                if (!defined $entryActions) {
                    $errorString =
                      "$file:$.: substitution found outside entry/key pattern";
                    $in->close;
                    return 0;
                }

                # added {} to entryActions
                push(
                    @{$entryActions},
                    {   'action' => "subst\u$action",
                        'subst'  => $subst,
                    });
                next;
            }

            # An entry deletion
            if (/^\s*delete$/) {
                if (!defined $keyActions) {
                    $errorString = "$file:$.: delete entry found outside key";
                    $in->close;
                    return 0;
                }
                if (!defined $entryActions) {
                    $errorString =
                      "$file:$.: delete entry found outside entry/key pattern";
                    $in->close;
                    return 0;
                }

                # added {} to entryActions
                push(
                    @{$entryActions},
                    {   'action' => 'delete',
                        'subst'  => undef,
                    });
                next;
            }
            $errorString = "$file:$.: unexpected line";
            $in->close;
            return 0;
        }
        $in->close;
        return 1;
    }

    #
    # Given a ini object, modify it by applying the filtering commands
    # (deletions and substitutions) contained in the filter object.
    # Returns true iff there are no problems.
    #
    sub filter
    {
        my ($filter, $ini) = @_;

        my $key;
        foreach $key (@{$ini->keys}) {    # was unblessed references
            my $keyFilt;
            foreach $keyFilt (@{$filter->{'keyFilters'}}) {
                next if ($key->name !~ /^$keyFilt->{'keyPat'}$/i);
                if ($keyFilt->{'deleteAll'}) {
                    $ini->removeKey($key);
                    next;                 # no point in going on...
                }

                # remove end block here $keyFilt was not defined
                # Must be entry substituions/deletions
                my $keyAction;
                foreach $keyAction (@{$keyFilt->{'keyActions'}}) {
                    my $field;
                    foreach $field (@{$key->fields}) {
                        my $target =
                            $keyAction->{'matchOn'} eq 'name'
                          ? $field->name
                          : $field->value;
                        next if ($target !~ /^$keyAction->{'matchPat'}$/i);

                        #
                        # Have a match - carry out entry actions
                        #
                        my $entryAction;
                        foreach $entryAction (@{$keyAction->{'entryActions'}}) {
                            if ($entryAction->{'action'} eq 'substName') {
                                my $name = $field->name;
                                eval "\$name =~ $entryAction->{'subst'}";
                                if ($@ ne '') {
                                    $errorString = "error substituting " .
                                      "$target using $keyAction->{'subst'}";
                                    return undef;
                                }
                                $field->name($name);
                            }
                            elsif ($entryAction->{'action'} eq 'substValue') {
                                my $value = $field->value;
                                eval "\$value =~ $entryAction->{'subst'}";
                                if ($@ ne '') {
                                    $errorString = "error substituting " .
                                      "$target using $keyAction->{'subst'}";
                                    return undef;
                                }
                                $field->value($value);
                            }
                            elsif ($entryAction->{'action'} eq 'delete') {
                                $key->removeField($field);
                                last;
                            }
                            else {
                                $errorString = "inifilter::filter: internal " .
                                  "error - unknown entry action: " .
                                  "$entryAction->{'action'}";
                                return undef;
                            }
                        }
                    }
                }
            }
        }

        return 1;
    }    # End Sub Filter

    #
    # Export all filtering commands to the command line (mainly for DEBUG)
    # (deletions and substitutions) contained in the filter object.
    # Returns true iff there are no problems.
    #
    sub export
    {
        my ($filter) = @_;

        my $keyFilt;
        foreach $keyFilt (@{$filter->{'keyFilters'}}) {
            print "keyPat = " . $keyFilt->{'keyPat'} . "\n";
            if ($keyFilt->{'deleteAll'}) {
                print "deleteAll = " . $keyFilt->{'deleteAll'} . "\n";
            }

            # remove end block here $keyFilt was not defined
            # Must be entry substituions/deletions
            my $keyAction;
            foreach $keyAction (@{$keyFilt->{'keyActions'}}) {

                print "matchOn = " . $keyAction->{'matchOn'} . "\n";
                print "matchPat = " . $keyAction->{'matchPat'} . "\n";

                #
                # Have a match - carry out entry actions
                #
                my $entryAction;
                foreach $entryAction (@{$keyAction->{'entryActions'}}) {
                    print "entryAction = " . $entryAction->{'action'} . "\n";
                    if ($entryAction->{'action'} eq 'substName') {
                        print "subst name = " . $entryAction->{'subst'} . "\n";
                    }
                    elsif ($entryAction->{'action'} eq 'substValue') {
                        print "subst value = " . $entryAction->{'subst'} . "\n";
                    }
                    elsif ($entryAction->{'action'} eq 'delete') {
                        print "delete = " . $entryAction->{'subst'} . "\n";
                        last;
                    }
                    else {
                        $errorString = "inifilter::export: internal error " .
                          "- unknown entry action: $entryAction->{'action'}";
                        return undef;
                    }
                }
            }
        }

        return 1;
    }    # End Sub Export

}    # End package App::IniDiff::IniFile::Filter

=pod

=head1 AUTHOR

    Michael Rendell, Memorial University of Newfoundland

=head1 MAINTAINERS
 
    Jeremy Squires <j.squires at computer.org>

=head1 SOURCE

=over 4

=item * The source for this package is available here:

L<https://github.com/jeremysquires/App-IniDiff>

=back

=head1 ACKNOWLEDGEMENTS

    Michael Rendell, Memorial University of Newfoundland
    produced the first version of the Regutils package from which
    this package was derived.

=over 4

=item * It is still available from:

L<https://sourceforge.net/projects/regutils/>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-inidiff-inifile at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-IniDiff-IniFile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::IniDiff::IniFile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-IniDiff-IniFile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-IniDiff-IniFile>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-IniDiff-IniFile>

=item * Search CPAN

L<https://metacpan.org/release/App-IniDiff-IniFile>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 1998 Memorial University of Newfoundland

This is free software, licensed under:

The GNU General Public License, Version 3, July 2007

See F<LICENSE>

=cut

1; # End of App::IniDiff::IniFile


