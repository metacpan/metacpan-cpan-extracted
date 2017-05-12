package CGI::NoPoison;
use strict;
use Carp 'croak';

our $VERSION = '3.11';

#note that we are overriding AUTOLOADed methods in CGI.pm in this way
#so we aren't having to use the "no warnings 'redefine'" pragma ;)
sub CGI::FETCH {
    return $_[0] if $_[1] eq 'CGI';
    return undef unless defined $_[0]->param($_[1]);
	#Instead of returning a null-byte packed list, introducing 
	#potential security problems, why not instead return an
	#anonymous array and just dereference it later ? 
    #return join("\0",$_[0]->param($_[1]));
	my @a = $_[0]->param($_[1]);
	if ( scalar( @a ) > 1 )
	{
		return [$_[0]->param($_[1])]; # return anon-array if more than one element
	}
	else
	{
		return $_[0]->param($_[1]); # behave normally otherwise, so we have a true drop-in replacement
	}
}

#and if we're going to do THAT, well, we might as well
sub CGI::SplitParam {
    my ($param) = @_;
    #my (@params) = split ("\0", $param);	
    #my (@params) =  @{$param}; # wait, why bother with this?
    #return (wantarray ? @params : $params[0]);
    return (wantarray ? @{$param} : @{$param}[0]);# when you can just do this, instead! :)
}

#and also should probably 
sub CGI::STORE {
    my $self = shift;
    my $tag  = shift;
	# this should now be a reference to a named or an anonymous array
	# ala $vals = [ qw(list goes here) ]; or $vals = \@ary;
    my $vals = shift;    
	#my @vals = index($vals,"\0")!=-1 ? split("\0",$vals) : $vals;
	croak "Value list not an array reference"
		unless ref($vals) eq 'ARRAY';
    #$self->param(-name=>$tag,-value=>\@vals);
    $self->param(-name=>$tag,-value=>$vals);# look ma, it's *already* a reference!
}

1;
__END__

=pod 

=head1 NAME

CGI::NoPoison - No Poison Null Byte in CGI->Vars

=head1 SYNOPSIS

	use CGI;
	use CGI::NoPoison

	my $m = CGI->new();
	$m->param(
		-name=>'amplifier',
		-value=>['nine', 'ten', 'up to eleven'],
	);
	my %h = $m->Vars();
	# look ma, no splitting on poison null-bytes ( '\0' )!
	print "$_ => ", join ", ", @{$h{$_}} for keys %h;
   
	print "This one goes ", ($m->param('amplifier'))[2];


=head1 DESCRIPTION

Simplicity itself. Instead of using a null-byte to separate multi-valued fields
why not just use what CGI.pm B<already> uses to store the values internally? 

"What's that?", you ask? Why, it's an anonymous array, of course, like anyone 
sensible would use. cgi-lib.pl may have been fine years and years ago, but this now-archaic throwback
no longer needs us to bow to its demands. (is anyone still actually using it? yikes.)

This does, however change how you parse CGI->Vars() (as an anon-array, not a C<\0>-packed string)
and also how you set params. 

B<NOW> you can properly test for inserted null-bytes in a secure environment B<WHILE> taking advantage 
of the convenience of the Vars() function.

=head1 USAGE

Include the 'use CGI::NoPoison' only after you've already done 'use CGI' so that
it can replace the AUTOLOAD routines with these replacement functions instead.

(By the way, the CGI.pm internal functions that we replace are: CGI::SplitParam, CGI::STORE, and CGI::FETCH, 
not that you'd actually ever use these directly :)

Then, all you have to do is remember that anywhere you would have previously used C<\0> to
split on, or to string-pack, just take an array reference, or use an anonymous array instead. See the L<CGI|CGI/"FETCHING THE PARAMETER LIST AS A HASH"> module
documentation for details.

=head1 BUGS

None so far. :)

Well, this may actually be a pretty wonky way of replacing those functions in CGI.pm, but hey, it worked here. YMMV. :D

=head1 SUPPORT

Yer on yer own with this one. Hopefully Lincoln Stein will get around to adding this as a -nopoison pragma to CGI.pm at some point. 

=head1 AUTHOR

	Scott R. Godin
	CPAN ID: SGODIN
	Laughing Dragon Services
	nospam@webdragon.net
	http://www.webdragon.net/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<http://groups-beta.google.com/group/perl.beginners.cgi/msg/7fcdb6b3476915de?hl=en>
( or message-id <20050209020155.15512.qmail@lists.develooper.com> )

Google around for "poison null byte"

L<CGI>, L<perlref>

=cut

