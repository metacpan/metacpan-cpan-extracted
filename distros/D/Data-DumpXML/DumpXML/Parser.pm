package Data::DumpXML::Parser;

use strict;
use vars qw($VERSION @ISA);

$VERSION = "1.01";

require XML::Parser;
@ISA=qw(XML::Parser);

sub new
{
    my($class, %arg) = @_;
    $arg{Style} = "Data::DumpXML::ParseStyle";
    $arg{Namespaces} = 1;
    return $class->SUPER::new(%arg);
}

package Data::DumpXML::ParseStyle;

use Array::RefElem qw(av_push hv_store);

sub Init
{
    my $p = shift;
    $p->{dump_data} = [];
    push(@{$p->{stack}}, $p->{dump_data});
}

sub Start
{
    my($p, $tag, %attr) = @_;
    $p->{in_str}++ if $tag eq "str" || $tag eq "key";
    my $obj = [\%attr];
    push(@{$p->{stack}[-1]}, $obj);
    push(@{$p->{stack}}, $obj);
}

sub Char
{
    my($p, $str) = @_;
    return unless $p->{in_str};
    push(@{$p->{stack}[-1]}, $str);
}

sub End
{
    my($p, $tag) = @_;
    my $obj = pop(@{$p->{stack}});
    my $attr = shift(@$obj);

    my $ref;

    if ($tag eq "str" || $tag eq "key") {
	$p->{in_str}--;
        my $val = join("", @$obj);
        if (my $enc = $attr->{encoding}) {
            if ($enc eq "base64") {
                require MIME::Base64;
                $val = MIME::Base64::decode($val);
            }
            else {
                warn "Unknown encoding '$enc'";
            }
        }
	$ref = \$val;
    }
    elsif ($tag eq "ref") {
	my $val = $obj->[0];
	$ref = \$val;
    }
    elsif ($tag eq "array" || $tag eq "data") {
	my @val;
	for (@$obj) {
	    av_push(@val, $$_);
	}
	$ref = \@val;
    }
    elsif ($tag eq "hash") {
	my %val;
	while (@$obj) {
	    my $keyref = shift @$obj;
	    my $valref = shift @$obj;
	    hv_store(%val, $$keyref, $$valref);
	}
	$ref = \%val;
    }
    elsif ($tag eq "undef") {
	my $val = undef;
	$ref = \$val;
    }
    elsif ($tag eq "alias") {
	$ref = $p->{alias}{$attr->{ref}};
    }
    else {
	my $val = "*** $tag ***";
	$ref = \$val;
    }

    $p->{stack}[-1][-1] = $ref;

    if (my $class = $attr->{class}) {
	if (exists $p->{Blesser}) {
	    my $blesser = $p->{Blesser};
	    if (ref($blesser) eq "CODE") {
		&$blesser($ref, $class);
	    }
	}
	else {
	    bless $ref, $class;
	}
    }

    if (my $id = $attr->{id}) {
	$p->{alias}->{$id} = $ref;
    }
}

sub Final
{
    my $p = shift;
    my $data = $p->{dump_data}[0];
    return $data;
}

1;

__END__

=head1 NAME

Data::DumpXML::Parser - Restore data dumped by Data::DumpXML

=head1 SYNOPSIS

 use Data::DumpXML::Parser;

 my $p = Data::DumpXML::Parser->new;
 my $data = $p->parsefile(shift || "test.xml");

=head1 DESCRIPTION

C<Data::DumpXML::Parser> is an C<XML::Parser> subclass that can
recreate the data structure from an XML document produced by
C<Data::DumpXML>.  The parserfile() method returns a reference to an
array of the values dumped.

The constructor method new() takes a single additional argument to
that of C<XML::Parser>:

=over

=item Blesser => CODEREF

A subroutine that is invoked to bless restored objects.  The
subroutine is invoked with two arguments: a reference to the object,
and a string containing the class name.  If not provided, the built-in
C<bless> function is used.

For situations where the input file cannot necessarily be trusted and
blessing arbitrary Classes might give malicious input the ability
to exploit the DESTROY methods of modules used by the code, it is a
good idea to provide a no-op blesser:

  my $p = Data::DumpXML::Parser->new(Blesser => sub {});

=back

=head1 SEE ALSO

L<Data::DumpXML>, L<XML::Parser>

=head1 AUTHOR

Copyright 2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
