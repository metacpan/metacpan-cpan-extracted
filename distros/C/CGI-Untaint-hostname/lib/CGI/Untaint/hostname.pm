
package CGI::Untaint::hostname;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.1;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

CGI::Untaint::hostname - untaint DNS host names 

=head1 SYNOPSIS

  use CGI::Untaint::hostname
  my $handler = CGI::Untaint->new( $q->Vars() );
  my $filename = $handler->extract( -as_hostname => 'some-host.some-domain.com' );


=head1 DESCRIPTION

This module untaints and validates DNS host names. Validation means that the
name has the correct syntax specified in RFC 1035 section 3.5 (page 10), not
that it exists (after all you could use this in a web front-end to a dns zone
maintenance system) anywhere in any form.

=head1 INSTALLATION

to install the module...

perl Build.PL
./Build
./Build test
./Build install


=head1 BUGS

None known. 

=head1 SUPPORT

E-mail the author

=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), CGI::Untaint, RFC 1035.

=cut

############################################# main pod documentation end ##

use base 'CGI::Untaint::object';


sub _untaint_re {
  return qr/^([\p{IsAlnum}\-.]+)$/;
}


################################################ subroutine header begin ##

=head2 is_valid

 Usage     : $self->is_valid
 Purpose   : Ensure that the hostname name is completely valid including length checking
 Returns   : true if the name is valid
 Argument  : the string to validate is in $self object
 Throws    : nothing
 Comments  :

See Also   : is_ok

=cut

################################################## subroutine header end ##

sub is_valid {
  my $self = shift;
  return is_ok ( $self->value);
}

################################################ subroutine header begin ##

=head2 is_ok

 Usage     : $self->is_ok($value)
 Purpose   : Perform syntax and length checking to validate the name
 Returns   : true if the name is valid
 Argument  : the string to validate
 Throws    : nothing of its own
 Comments  : RFC 1304 section 3.5 specificies the syntax and length limits on the names. Each section, separated by '.',
           : must start with a letter, end with a letter or digit, and have as interior
           : characters only letters, digits, and hyphen. The length of each section is  63 characters maximum.
           : While it is customary to have a two or three letter "top-level domain" suffix, this is not
           : required (cf ".arpa") 
           : N.B. while empirically it seems that registrars are registering names starting with digits, (e.g., 123.com) I find no 
           : basis for this in any RFC.
See Also   : is_ok

=cut

################################################## subroutine header end ##
sub is_ok {
my $value = shift;
my @parts = split/\./,$value;
my $label;
my $valid=1;
foreach $label (@parts)
  {
    $valid=0 unless (length $label <= 63) and ($label !~/^\-/);
}
return $valid;
}
1; #this line is important and will help the module return a true value
__END__

