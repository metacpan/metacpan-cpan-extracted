package Config::INI::Serializer;
BEGIN {
  $Config::INI::Serializer::AUTHORITY = 'cpan:SCHWIGON';
}
$Config::INI::Serializer::VERSION = '0.002';
use 5.006;
use strict;
use warnings;

# ABSTRACT: Round-trip INI serializer for nested data


# lightweight OO to the extreme, as we really don't need more
sub new {
        bless {}, shift;
}

# utility method, stolen from App::Reference, made internal here
sub _get_branch {
    my ($self, $branch_name, $create, $ref) = @_;
    my ($sub_branch_name, $branch_piece, $attrib, $type, $branch, $cache_ok);
    $ref = $self if (!defined $ref);

    # check the cache quickly and return the branch if found
    $cache_ok = (ref($ref) ne "ARRAY" && $ref eq $self); # only cache from $self
    $branch = $ref->{_branch}{$branch_name} if ($cache_ok);
    return ($branch) if (defined $branch);

    # not found, so we need to parse the $branch_name and walk the $ref tree
    $branch = $ref;
    $sub_branch_name = "";

    # these: "{field1}" "[3]" "field2." are all valid branch pieces
    while ($branch_name =~ s/^([\{\[]?)([^\.\[\]\{\}]+)([\.\]\}]?)//) {

        $branch_piece = $2;
        $type = $3;
        $sub_branch_name .= ($3 eq ".") ? "$1$2" : "$1$2$3";

        if (ref($branch) eq "ARRAY") {
            if (! defined $branch->[$branch_piece]) {
                if ($create) {
                    $branch->[$branch_piece] = ($type eq "]") ? [] : {};
                    $branch = $branch->[$branch_piece];
                    $ref->{_branch}{$sub_branch_name} = $branch if ($cache_ok);
                }
                else {
                    return(undef);
                }
            }
            else {
                $branch = $branch->[$branch_piece];
                $sub_branch_name .= "$1$2$3";   # accumulate the $sub_branch_name
            }
        }
        else {
            if (! defined $branch->{$branch_piece}) {
                if ($create) {
                    $branch->{$branch_piece} = ($type eq "]") ? [] : {};
                    $branch = $branch->{$branch_piece};
                    $ref->{_branch}{$sub_branch_name} = $branch if ($cache_ok);
                }
                else {
                    return(undef);
                }
            }
            else {
                $branch = $branch->{$branch_piece};
            }
        }
        $sub_branch_name .= $type if ($type eq ".");
    }
    return $branch;
}

# utility method, stolen from App::Reference, made internal here
sub _set {
    my ($self, $property_name, $property_value, $ref) = @_;
    #$ref = $self if (!defined $ref);

    my ($branch_name, $attrib, $type, $branch, $cache_ok);
    if ($property_name =~ /^(.*)([\.\{\[])([^\.\[\]\{\}]+)([\]\}]?)$/) {
        $branch_name = $1;
        $type = $2;
        $attrib = $3;
        $cache_ok = (ref($ref) ne "ARRAY" && $ref eq $self);
        $branch = $ref->{_branch}{$branch_name} if ($cache_ok);
        $branch = $self->_get_branch($1,1,$ref) if (!defined $branch);
    }
    else {
        $branch = $ref;
        $attrib = $property_name;
    }

    if (ref($branch) eq "ARRAY") {
        $branch->[$attrib] = $property_value;
    }
    else {
        $branch->{$attrib} = $property_value;
    }
}

# the serialize frontend method
sub serialize {
    my ($self, $data) = @_;
    $self->_serialize($data, "");
}

# recursive serialize method doing the actual work, internal
sub _serialize {
    my ($self, $data, $section) = @_;
    my ($section_data, $idx, $key, $elem);
    if (ref($data) eq "ARRAY") {
        for ($idx = 0; $idx <= $#$data; $idx++) {
            $elem = $data->[$idx];
            if (!ref($elem)) {
                $section_data .= "[$section]\n" if (!$section_data && $section);
                $section_data .= "$idx = $elem\n";
            }
        }
        for ($idx = 0; $idx <= $#$data; $idx++) {
            $elem = $data->[$idx];
            if (ref($elem)) {
                $section_data .= $self->_serialize($elem, $section ? "$section.$idx" : $idx);
            }
        }
    }
    elsif (ref($data)) {
        foreach $key (sort keys %$data) {
            $elem = $data->{$key};
            if (!ref($elem)) {
                no warnings 'uninitialized';
                $section_data .= "[$section]\n" if (!$section_data && $section);
                $section_data .= "$key = $elem\n";
            }
        }
        foreach $key (sort keys %$data) {
            $elem = $data->{$key};
            if (ref($elem)) {
                $section_data .= $self->_serialize($elem, $section ? "$section.$key" : $key);
            }
        }
    }

    return $section_data;
}

# the deserialize frontend method
sub deserialize {
    my ($self, $inidata) = @_;
    my ($data, $r, $line, $attrib_base, $attrib, $value);

    $data = {};

    $attrib_base = "";
    foreach $line (split(/\n/, $inidata)) {
        next if ($line =~ /^;/);  # ignore comments
        next if ($line =~ /^#/);  # ignore comments
        if ($line =~ /^\[([^\[\]]+)\] *$/) {  # i.e. [Repository.default]
            $attrib_base = $1;
        }
        if ($line =~ /^ *([^ =]+) *= *(.*)$/) {
            $attrib = $attrib_base ? "$attrib_base.$1" : $1;
            $value = $2;
            $self->_set($attrib, $value, $data);
        }
    }
    return $data;
}

# END of stolen ::App::Serialize::Ini

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::INI::Serializer - Round-trip INI serializer for nested data

=head1 SYNOPSIS

=over 4

=item Data to INI

 require Config::INI::Serializer;
 my $ini  = Config::INI::Serializer->new;
 my $data = { an         => 'arbitrary',
              collection => [ 'of', 'data', ],
              of         => {
                             arbitrary => 'depth',
                            },
            };
 my $ini_text = $ini->serialize($data);

=item INI to Data

 $data = $ini->deserialize($ini_text);

=item No functions are exported.

=back

=head1 DESCRIPTION

This library is the carved-out INI-file handling from
L<App::Context|App::Context>, namely the essential functions from
L<App:Serializer::Ini|App:Serializer::Ini> and
L<App::Reference|App::Reference>.

I<OH NOES - JET ANOTHR INI MOTULE!> - but this one turned out to work
better for INI-like nested data serialization where compatibility with
other modules is not as important. It is used in the
L<dpath|App::DPath> utility.

B<ACHTUNG!> The "round-trip ability" belongs to the data written by
the module itself. It does B<not> perfectly keep foreign data
structures. Carefully read the C<CAVEATS> section below.

=head1 METHODS

=head2 new

Constructor.

=over 4

=item Sample Usage:

    $serializer = Config::INI::Serializer->new;

=back

=head2 serialize

=over 4

=item Signature: $inidata = $serializer->serialize($data);

=item Param: $data (ref)

=item Return: $inidata (text)

=item Sample Usage:

    $serializer = Config::INI::Serializer->new;
    $inidata = $serializer->serialize($data);

=back

=head2 deserialize

=over 4

=item Signature: $data = $serializer->deserialize($inidata);

=item Param: $inidata (text)

=item Return: $data (ref)

=item Sample Usage:

    $serializer = Config::INI::Serializer->new;
    $data = $serializer->deserialize($inidata);
    print $serializer->dump($data), "\n";

=back

=head1 CAVEATS

=over 4

=item It is an extended, probably non-standard variant of INI.

It can read most of the other INI formats, but writing is done a bit
special to handle nested data.

So using this module is kind of a "one-way ticket to slammertown with
no return ticket" aka. vendor lock-in.

=item It turns ARRAYs into HASHes.

Array indexes are expressed like numbered hash keys:

 [list.0]
 ...
 [list.1]
 ...
 [list.2]
 ...
 [list.10]

which, when re-read, actually B<become> hash keys as there is no more
distinction after that. Besides losing the array structure this also
loses the order of elements.

=item It does not handle multiline values correctly.

They will written out straight like this

 key1 = This will be
 some funky multi line
 entry
 key2 = affe

but on reading you will only get
C<key1 = This will be> and
C<key2 = affe>.

At least it does not choke on the additional multilines, as long as
they don't contain a C<=> character.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Stephen Adkins is the author of the original code.

=back

I only carved it out into a separate module to provide it as a
light-weight dependency.

=head1 AUTHORS

=over 4

=item *

Stephen Adkins <spadkins@gmail.com>

=item *

Steffen Schwigon <ss5@renormalist.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Stephen Adkins, Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
