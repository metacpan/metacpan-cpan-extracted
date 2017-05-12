package CatalystX::Plugin::Blurb;
use strict;
use warnings;

our $VERSION = "0.03";

sub blurb {
    my $c = shift;
    $c->{__blurbs} ||= $c->flash->{__blurb} || [];
    unless ( @_ ) { return wantarray ? @{ $c->{__blurbs} } : $c->{__blurbs} };
    my @added = ref($_[0]) eq "ARRAY" ? @{$_[0]} : @_;
    for my $new ( @added )
    {
        my $raw = ref($new) eq "HASH" ? $new : { id => $new };
        $raw->{render} ||= $c->config->{__PACKAGE__}->{render};
        my $blurb = CatalystX::Plugin::Blurb::blurb->new( $raw );
        push @{$c->{__blurbs}}, $blurb;
    }
}

sub finalize {
    my $c = shift;
    $c->flash( __blurb => [ $c->blurb ] ) if $c->flash_blurb;
    $c->next::method(@_);
}

sub flash_blurb {
    my $c = shift;
    $c->{_flash_blurb} = shift if @_;
    $c->{_flash_blurb};
}

{
    package CatalystX::Plugin::Blurb::blurb;
    use parent "Class::Accessor::Fast";
    use overload '""' => "render_or_default";

    __PACKAGE__->mk_accessors( qw( id priority mime_type content
                                   render ) );

    sub render_or_default {
        my $self = shift;
        return $self->render->($self) if $self->render;
        $self->content || $self->id || $self;
    }
}

1;

__END__

=pod

=head1 NAME

CatalystX::Plugin::Blurb - (alpha software) handle transient messages and UI elements.

=head1 VERSION

0.03

=head1 NOTICE

This is not something I'd encourage you to use yet. I am releasing it to the CPAN so it can be available for building another package. This is half done. It was written well over a year ago and barely used or touched since. It might be a mistake. It might be abandoned. If you try it though, have fun.

=head1 SYNOPSIS

 use Catalyst qw(
                 Unicode
                 Session
                 +CatalystX::Plugin::Blurb
                 );

=head1 DESCRIPTION

=over 4

=item blurb


=item flash_blurb

Blurbs are normally only kept for a single response. If you set C<flash_blurb> to true the blurbs will be kept for the next request via L<flash|Catalyst::Plugin::Session/flash>.

=item * finalize

Puts the blurbs into flash for the next request if C<flash_blurb> has been set.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-catalyst-plugin-blurb@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.

=head1 TODO

Flash blurb interface is wrong. They should be just like blurbs, not a switch. They should also have an expiration baked in.

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Ashley Pond V.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut


 stash_it => 1, # default
 flash_it

...? NO?

EXPIRES? One view? 2 minutes? ...?

 accessor: blurb

 order_by
  fifo
  lifo
  short2long
  long2short
  priority
  render

 sub object:
  mime_type
  content
  priority

