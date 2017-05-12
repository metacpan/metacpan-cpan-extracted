package CGI::ConvertParam;

require 5.00;
use vars qw($VERSION $AUTOLOAD);
use strict;

$VERSION = '0.05';

sub new
{
    my $class = shift;
    my $cgi = shift;
    my $self = bless {}, $class;
    $self->query($cgi);
    $self->initialize;
    $self;
}


sub AUTOLOAD
{
    my $self = shift;
    return if $AUTOLOAD =~ /::DESTROY$/;
    my $method = $AUTOLOAD;
    $method =~ s/.*://;

    $self->query->$method(@_);
}


sub convert_all_param
{
    my $self = shift;
    my $query = $self->query;
    foreach my $name ($query->param) {
        $query->param(
            $name,
            map {$self->do_convert_all_param($_)} $query->param($name)
        );
    }
    $self;
}


sub param
{
    my $self = shift;
    my @args  = map { $self->do_convert_on_set($_) } @_;
    my @value = map { $self->do_convert_on_get($_) }
                $self->query->param(@args);
    return wantarray ? @value : $value[0];
}


sub query
{
    my $self = shift;
    if (@_) { $self->{_cgi_convertparam_cgi_instance} = shift }
    $self->{_cgi_convertparam_cgi_instance};
}



sub initialize
{
    my $self = shift;
    # Please OVERRIDE
}


sub do_convert_all_param
{
    my $self = shift;
    my $parameter_value = shift;
    # Please OVERRIDE
    return $parameter_value;
}


sub do_convert_on_get
{
    my $self = shift;
    my $parameter_value = shift;
    # Please OVERRIDE
    return $parameter_value;
}


sub do_convert_on_set
{
    my $self = shift;
    my $parameter_value = shift;
    # Please OVERRIDE
    return $parameter_value;
}


1;
__END__

=head1 NAME

CGI::ConvertParam - Decorator class which adds several hook to CGI::param().

=head1 SYNOPSIS

  package CGI::ConvertParam::OngetUTF8;
  use base 'CGI::ConvertParam';
  use Jcode;

  sub do_convert_on_get
  {
      my $self = shift;
      my $parameter_value = shift;
      return Jcode->new($parameter_value)->utf8;
  }
  1;

  package client;
  use CGI;
  use CGI::ConvertParam::OngetUTF8;

  $query = CGI::ConvertParam::OngetUTF8->new(CGI->new);
  print $query->param('parameter_foo');

=head1 DESCRIPTION

CGI::ConvertParam and the subclass are Decorator which adds some hooks to the CGI::param() method.

=head1 EXAMPLE

=head2 All parameters are converted to EUC-JP

  package CGI::ConvertParam::EUC;
  use base 'CGI::ConvertParam';
  use Jcode;

  sub initialize
  {
      my $self = shift;
      $self->convert_all_param;
  }

  sub do_convert_all
  {
      my $self    = shift;
      my $strings = shift;
      return Jcode->new($strings)->euc;
  }
  1;

  package main;
  use CGI;
  use CGI::ConvertParam::EUC;
  my $query = CGI::ConvertParam::EUC->new(CGI->new);
  print 'Name(EUC-JP):', $query->param('NAME');

=head2 Convert Shift-JIS on Setting the value or values of a named parameter:

  package CGI::ConvertParam::OnsetShiftJIS;
  use base 'CGI::ConvertParam';
  use Jcode;

  sub do_convert_on_set
  {
      my $self    = shift;
      my $strings = shift;
      return Jcode->new($strings)->sjis;
  }
  1;


  package main;
  use CGI;
  use CGI::ConvertParam::OnsetShiftJIS;
  my $query = CGI::ConvertParam::OnsetShiftJIS->new(CGI->new);
  $query->param(NAME => $value);
  print 'Name(Shift-JIS):', $query->param('NAME');

=head2 Convert UTF-8 on Fetching the value or values of a named parameter:

  package CGI::ConvertParam::OngetUTF8;
  use base 'CGI::ConvertParam';
  use Jcode;

  sub do_convert_on_get
  {
      my $self    = shift;
      my $strings = shift;
      return Jcode->new($strings)->utf8;
  }
  1;


  package main;
  use CGI;
  use CGI::ConvertParam::OngetUTF8;
  my $query = CGI::ConvertParam::OngetUTF8->new(CGI->new);
  $query->param(NAME => $value);
  print 'Name(UTF-8):', $query->param('NAME');

=head1 METHOD

=head2 Class method

=over 4

=item new(I<CGI_OBJECT>)

The B<new()> method is the constructor for a CGI::ConvertParam and sub-class. I<CGI_BOJECT> is the reference of the CGI instance. It return a specialized CGI instance.

=back

=head2 Instance method

=over 4

=item convert_all_param()

This method is convert the all named parameter.

=back

=head2 Subclassing and Override methods

CGI::ConvertParam implements some methods which are expected to be overridden by implementing them in your subclass module. These methods are as follows:

=over 4

=item initialize()

This method is colled by the inherited new() constructor method. The B<initialize()> method should be used to define the following property/methods:

=item do_convert_on_set()

This method is called by B<param('name' =E<gt> $value)> method. The B<do_convert_on_set()> method shuld be used to define the converter.

=item do_convert_on_get()

This method is called by B<param('name')> method. The B<do_convert_on_get()> method shuld be used to define the converter.

=item do_convert_all_param

This method is called by B<convert_all_param()> method. The B<do_convert_all_param()> method shuld be used to define the converter.

=back

=head2 Data-access method

=over 4

=item query()

This method is return the original CGI instance.

=back

=head1 SEE ALSO

L<CGI>

=head1 AUTHOR

OYAMA Hiroyuki <oyama@crayfish.co.jp>
http://perl.infoware.ne.jp/

=head1 COPYRIGHT

Copyright(c) 2000, OYAMA Hiroyuki. Japan. All rights reserved.

CGI::ConvertParam class may be copied only under the terms of either the Artistic License or the GNU General Public License, which may be found in the Perl 5 source kit.

=cut
