package Acme::PrettyCure::Girl::Role;
use utf8;
use Moo::Role;

use Encode;
use Furl;
use Cache::LRU;
use Net::DNS::Lite;
use Imager;

$Net::DNS::Lite::CACHE = Cache::LRU->new(size => 256);

requires qw(human_name precure_name challenge image_url);

has 'is_precure' => (
    is  => 'rw',
    isa => sub { die "$_[0] is not a boolean" if $_[0] !~ /^[01]$/ },
    default => sub {0}
);

sub say {
    my ($self, $text) = @_;
    my $color = $self->color;
    if ( defined $color ) {
        print "\e[38;5;${color}m";
    }
    print encode_utf8("$text\n");
    if ( defined $color ) {
        print "\e[0m";
    }
}

sub color { undef }

sub name {
    my $self = shift;

    return $self->is_precure ? $self->precure_name : $self->human_name;
}

sub transform {
    my ($self, $buddy) = @_;

    die "already transformed" if $self->is_precure;

    $self->is_precure(1);

    $self->say($_) for $self->challenge;

    return $self;
}

sub image {
    my $self = shift;

    my $furl = Furl::HTTP->new(
        agent     => 'Acme-PrettyCure',
        inet_aton => \&Net::DNS::Lite::inet_aton,
        timeout   => 60,
    );
    my ( $minor_version, $status, $message, $headers, $content ) =
      $furl->request( method => 'GET', url => $self->image_url, );

    my $img = Imager->new();
    my $type;
    if ($self->image_url =~ /\.gif$/) {
        $type = 'gif';
    }
    elsif ($self->image_url =~ /\.png$/) {
        $type = 'png';
    }
    elsif ($self->image_url =~ /\.jpe?g$/) {
        $type = 'jpeg';
    }
    $img->read(data => $content, type => $type) or die $img->errstr;

    open my $ah, '|-', qw/aview -reverse -driver curses/ or die "aview:$!";
    $img->write( fh => $ah, type => 'pnm' ) or die $img->errstr;
    close($ah);
}

1;
__END__

=head1 NAME

Acme::PrettyCure::Girl::Role

=head1 SYNOPSIS

  my ($tsubomi,) = Acme::PrettyCure->girls('HeartCatch');
  say $tsubomi->name;

  $tsubomi->transform;

  say $tsubomi->name;

=head1 DESCRIPTION

  Pretty Cure Girls.

=head1 METHODS

=head2 name

return her name. if she transformed, return precure name.

=head2 transform

return girl can transform.

=head2 attributes

- human_name
- precure_name
- (fairy_name)
- birthday
- age
- blood_type

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara at gmail.comE<gt>

=head1 SEE ALSO

C<Acme::MorningMusume>, C<Acme::AKB48>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
