#
# This file is part of AnyEvent-Riak
#
# This software is copyright (c) 2014 by Damien Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;
use FindBin qw($Bin);

my @content = split(m|\n|, do{local(@ARGV,$/)="$Bin/riak.proto";(<>)});

my $pod = "package AnyEvent::Riak::Documentation;\n\n1;\n\n";

my $current_comment = '';
my $request_name = '';
my $response_name = '';
my $object_name = '';

my %enums;
my $enum_name = '';

my $methods_pod = "=head1 METHODS\n\n";
my $responses_pod = "=head1 RESPONSE OBJECTS\n\n";
my $objects_pod = "=head1 OTHER OBJECTS\n\n";

my $current_pod = '';

my %mapper = (
  bytes => string =>
  uint32 => number =>
  bool => boolean =>
);

while (defined ($_ = shift @content)) {

state $c++;
    s/^\s*$//;
    length or
      $current_comment = '',
      next;

    if (m|^\s*//\s*([A-Z]?)(.*)$|) {
        $current_comment .= ($1 ? ($current_comment ? ". $1$2" : "$1$2"): " $2");
        next;
    }

    my $postfix_comment = '';
    s|//\s*(.*)$||
      and $postfix_comment = $1;

    if (/^message Rpb(\w+)Req {$/) {
        $request_name = $1;
        my $method_name = _from_camel($request_name);
        $current_pod .= "=head2 $method_name\n\n";
        $current_comment
          and $current_pod .= "$current_comment\n\n";
        $current_comment = '';
        $current_pod .= "=over\n\n";
        next;
    }
    if (/^message (Rpb\w+Resp) {$/) {
        $response_name = $1;
        $current_pod .= "=head2 $response_name\n\n";
        $current_comment
          and $current_pod .= "$current_comment\n\n";
        $current_comment = '';
        $current_pod .= "=over\n\n";
        next;
    }
    if (/^message (Rpb\w+) {$/) {
        $object_name = $1;
        next;
    }
    if (/^\s*}$/) {
        if ($enum_name) {
            $enum_name = '';
            next;
        }
        $current_pod .= "=back\n\n";
        if ($request_name) {
            $request_name = '';
            $methods_pod .= $current_pod;
            $current_pod = '';
            next;
        }
        if ($response_name) {
            $response_name = '';
            $responses_pod .= $current_pod;
            $current_pod = '';
            next;
        }
        if ($object_name) {
            $object_name = '';
            $objects_pod .= $current_pod;
            $current_pod = '';
            next;
        }
        die "mofa";
    }
    if (/^    enum (.*) {/) {
        $enum_name = $1;
        # $current_pod .= "=item $1\n\n";
        # $current_comment
        #   and $current_pod .= "$current_comment\n\n";
        # $current_pod .= "=over\n\n";
        next;
    }
    if (/^\s+(.*)$/) {
        my $item = $1;
        $item =~ s/ = \d+;$//;
        if ($enum_name) {
            push @{$enums{$enum_name} //= []}, $item;
            next;
        }
        my ($p1, $type, $name) = split(/\s+/, $item);
        defined $name or
          say STDERR "$c ($_)";
        $current_pod .= "=item $name\n\n";
        $type = $mapper{$type} // $type;
        if (exists $enums{$type}) {
            $type = 'one of ' . join(', ', map { "'$_'" } @{$enums{$type}} )
        }
        $current_pod .= "$p1, $type\n\n";
        $current_comment
          and $current_pod .= $current_comment;
        $postfix_comment
          and $current_pod .= ($current_comment ? '. ': '') . $postfix_comment;
        $postfix_comment || $postfix_comment
          and $current_pod .= "\n\n";
        $current_comment = '';
        next;
    }
}

$pod .= $methods_pod . $responses_pod . $objects_pod;

say $pod;

sub _from_camel {
    my $s = $_[0];
    $s =~ s/(.)([A-Z])([a-z])/$1 . '_' . lc($2) . $3/ge;
    $s =~ s/^([A-Z])([a-z])/lc($1) . $2/e;
    $s;
}
