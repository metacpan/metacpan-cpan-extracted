package App::DPath;
# git description: v0.10-5-gd6d7a5e

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Cmdline tool around Data::DPath
$App::DPath::VERSION = '0.11';
use 5.008; # Data::DPath requires it
use strict;
use warnings;

use Scalar::Util 'reftype';

sub read_in
{
        #my ($c, $file) = @_;
        my ($file, $intype, $yamlmod) = @_;

        $intype ||= 'yaml';
        my $data;
        my $filecontent;
        {
                local $/;
                if ($file eq '-') {
                        $filecontent = <STDIN>;
                }
                else
                {
                        open (my $FH, "<", $file) or die "dpath: cannot open input file $file.\n";
                        $filecontent = <$FH>;
                        close $FH;
                }
        }

        if (not defined $filecontent or $filecontent !~ /[^\s\t\r\n]/ms) {
                die "dpath: no meaningful input to read.\n";
        }

        if ($intype eq "yaml") {
                require YAML::Any;
                if ($yamlmod) {
                        @YAML::Any::_TEST_ORDER=($yamlmod);
                } else {
                        @YAML::Any::_TEST_ORDER=(qw(YAML::XS YAML::Old YAML YAML::Tiny)); # no YAML::Syck
                }
                $data = [YAML::Any::Load($filecontent)];
        }
        elsif ($intype eq "json") {
                require JSON;
                $data = JSON::decode_json($filecontent);
        }
        elsif ($intype eq "xml")
        {
                require XML::Simple;
                my $xs = new XML::Simple;
                $data  = $xs->XMLin($filecontent, KeepRoot => 1);
        }
        elsif ($intype eq "ini") {
                require Config::INI::Serializer;
                my $ini = Config::INI::Serializer->new;
                $data = $ini->deserialize($filecontent);
        }
        elsif ($intype eq "cfggeneral") {
                require Config::General;
                my %data = Config::General->new(-String => $filecontent,
                                                -InterPolateVars => 1,
                                               )->getall;
                $data = \%data;
        }
        elsif ($intype eq "dumper") {
                eval '$data = my '.$filecontent;
        }
        elsif ($intype eq "tap") {
                require TAP::DOM;
                require TAP::Parser;
                $data = new TAP::DOM( tap => $filecontent, $TAP::Parser::VERSION > 3.22 ? (version => 13) : () );
        }
        elsif ($intype eq "taparchive") {
                require TAP::DOM::Archive;
                require TAP::Parser;
                $data = new TAP::DOM::Archive( filecontent => $filecontent, $TAP::Parser::VERSION > 3.22 ? (version => 13) : () );
        }
        else
        {
                die "dpath: unrecognized input format: $intype.\n";
        }
        return $data;
}

sub _format_flat_inner_scalar
{
    my ($result) = @_;

    no warnings 'uninitialized';

    return "$result";
}

sub _format_flat_inner_array
{
        my ($opt, $result) = @_;

        no warnings 'uninitialized';

        return
         join($opt->{separator},
              map {
                   # only SCALARS allowed (where reftype returns undef)
                   die "dpath: unsupported innermost nesting (".reftype($_).") for 'flat' output.\n" if defined reftype($_);
                   "".$_
                  } @$result);
}

sub _format_flat_inner_hash
{
        my ($opt, $result) = @_;

        no warnings 'uninitialized';

        return
         join($opt->{separator},
              map { my $v = $result->{$_};
                    # only SCALARS allowed (where reftype returns undef)
                    die "dpath: unsupported innermost nesting (".reftype($v).") for 'flat' output.\n" if defined reftype($v);
                    "$_=".$v
                  } keys %$result);
}

sub _format_flat_outer
{
        my ($opt, $result) = @_;

        no warnings 'uninitialized';

        my $output = "";
        die "dpath: can not flatten data structure (undef) - try other output format.\n" unless defined $result;

        my $A = ""; my $B = ""; if ($opt->{fb}) { $A = "["; $B = "]" }
        my $fi = $opt->{fi};

        if (!defined reftype $result) { # SCALAR
                $output .= $result."\n"; # stringify
        }
        elsif (reftype $result eq 'SCALAR') { # blessed SCALAR
                $output .= $result."\n"; # stringify
        }
        elsif (reftype $result eq 'ARRAY') {
                for (my $i=0; $i<@$result; $i++) {
                        my $entry  = $result->[$i];
                        my $prefix = $fi ? "$i:" : "";
                        if (!defined reftype $entry) { # SCALAR
                                $output .= $prefix.$A._format_flat_inner_scalar($entry)."$B\n";
                        }
                        elsif (reftype $entry eq 'ARRAY') {
                                $output .= $prefix.$A._format_flat_inner_array($opt, $entry)."$B\n";
                        }
                        elsif (reftype $entry eq 'HASH') {
                                $output .= $prefix.$A._format_flat_inner_hash($opt, $entry)."$B\n";
                        }
                        else {
                                die "dpath: can not flatten data structure (".reftype($entry).").\n";
                        }
                }
        }
        elsif (reftype $result eq 'HASH') {
                my @keys = keys %$result;
                foreach my $key (@keys) {
                        my $entry = $result->{$key};
                        if (!defined reftype $entry) { # SCALAR
                                $output .= "$key:"._format_flat_inner_scalar($entry)."\n";
                        }
                        elsif (reftype $entry eq 'ARRAY') {
                                $output .= "$key:"._format_flat_inner_array($opt, $entry)."\n";
                        }
                        elsif (reftype $entry eq 'HASH') {
                                $output .= "$key:"._format_flat_inner_hash($opt, $entry)."\n";
                        }
                        else {
                                die "dpath: can not flatten data structure (".reftype($entry).").\n";
                        }
                }
        }
        else {
                die "dpath: can not flatten data structure (".reftype($result).") - try other output format.\n";
        }

        return $output;
}

sub _format_flat
{
        my ($opt, $resultlist) = @_;

        my $output = "";
        $opt->{separator} = ";" unless defined $opt->{separator};
        $output .= _format_flat_outer($opt, $_) foreach @$resultlist;
        return $output;
}

sub write_out
{
        my ($opt, $resultlist) = @_;

        my $output = "";
        my $outtype = $opt->{outtype} || 'yaml';
        if ($outtype eq "yaml")
        {
                require YAML::Any;
                if ($opt->{'yaml-module'}) {
                        @YAML::Any::_TEST_ORDER=($opt->{'yaml-module'});
                } else {
                        @YAML::Any::_TEST_ORDER=(qw(YAML::XS YAML::Old YAML YAML::Tiny)); # no YAML::Syck
                }
                $output .= YAML::Any::Dump($resultlist);
        }
        elsif ($outtype eq "json")
        {
                eval "use JSON -convert_blessed_universally";
                my $json = JSON->new->allow_nonref->pretty->allow_blessed->convert_blessed;
                $output .= $json->encode($resultlist);
        }
        elsif ($outtype eq "ini") {
                require Config::INI::Serializer;
                my $ini = Config::INI::Serializer->new;
                $output .= $ini->serialize($resultlist);
        }
        elsif ($outtype eq "dumper")
        {
                require Data::Dumper;
                $output .= Data::Dumper::Dumper($resultlist);
        }
        elsif ($outtype eq "xml")
        {
                require XML::Simple;
                my $xs = new XML::Simple;
                $output .= $xs->XMLout($resultlist, AttrIndent => 1, KeepRoot => 1);
        }
        elsif ($outtype eq "flat") {
                $output .= _format_flat( $opt, $resultlist );
        }
        else
        {
                die "dpath: unrecognized output format: $outtype.";
        }
        return $output;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DPath - Cmdline tool around Data::DPath

=head1 SYNOPSIS

    use App::DPath;

    my $path = '//some/dpath';
    my $data = App::DPath::read_in ($file);
    my @resultlist = dpath($path)->match($data);
    my $output = App::DPath::write_out ({}, \@resultlist);
    print $output;

=head1 DESCRIPTION

This module handles the input and output for the L<dpath> command.

=head1 SUBROUTINES

=head2 read_in

    my $data = App::DPath::read_in ($file, $intype, $yamlmod);

read_in takes a filename as its mandatory argument. It reads the data
from the file according to the type specified in the second argument
(which defaults to 'yaml') and returns the resulting data structure. Other
data types are: 'json', 'xml', 'ini', 'cfggeneral', 'dumper' and 'tap'.

The optional third argument specifies a list of modules to use to parse
YAML. The first available module in the list is used. If unspecified it
defaults to L<YAML::XS>, L<YAML::Old>, L<YAML> and L<YAML::Tiny>.

=head2 write_out

    my $formatted_out = App::DPath::write_out ($opt, $resultlist);

write_out returns the results as a string formatted according to the
options in the $opt hashref. Those options are

=over 4

=item outtype

One of 

=over 2

=item yaml (the default)

=item json

=item xml

=item ini

=item dumper

=item flat

=back

=item separator

For outtype=flat only. This option sets the field separator for the
output.

=item fb

For outtype=flat only. Display outer arrays inside square brackets.

=item fi

For outtype=flat only. Prefix outer array lines with index.

=item yaml-module

For outtype=yaml only. The YAML processing module to use. If not
provided it uses the same default as read_in.

=back

$resultstring is expected to be an arrayref, usually the result of
running a match against the read-in data.

=head1 SEE ALSO

L<dpath> is the command-line wrapper around this module. Its
documentation includes details of the "flat" output format along with
some usage examples.

L<Data::DPath> is the underlying path engine.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
