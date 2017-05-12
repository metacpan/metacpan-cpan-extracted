package CPAN::Mini::Growl;

use strict;
use 5.008_001;
our $VERSION = '0.03';

use base qw( CPAN::Mini );
use Digest::MD5;
use File::Spec;
use Mac::Growl;
use LWP::Simple;
use CPAN::DistnameInfo;
use Parse::CPAN::Authors;

my $AppName   = "CPAN::Mini::Growl";
my $EventType = "New Distribution";

sub update_mirror {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->SUPER::update_mirror;

    Mac::Growl::RegisterNotifications($AppName, [ $EventType ], [ $EventType ]);

    my $file  = File::Spec->catfile($self->{local}, "authors", "01mailrc.txt.gz");
    my $pause = Parse::CPAN::Authors->new($file);

    my $cache = File::Spec->catfile($self->{local}, "avatars");
    mkdir $cache, 0777 unless -e $cache;

    my @modules = grep !/CHECKSUMS/, keys %{$self->{recent}};
    for my $module (@modules) {
        if ($module =~ m!^authors/id/!) {
            my $dist = CPAN::DistnameInfo->new($module) or next;
            my $author = $pause->author($dist->cpanid)  or next;
            my $icon   = File::Spec->catfile($cache, $dist->cpanid . ".jpg");
            unless (-e $icon) {
                my $md5 = Digest::MD5::md5_hex($author->email);
                my $gravatar = "http://www.gravatar.com/avatar.php?gravatar_id=$md5&rating=G&size=80&default=http%3A%2F%2Fst.pimg.net%2Ftucs%2Fimg%2Fwho.png";
                LWP::Simple::mirror($gravatar, $icon);
            }

            my $msg = $author->name . " released " . $dist->distvname;
            Mac::Growl::PostNotification($AppName, $EventType, $dist->distvname, $msg, 0, 0, $icon);
        }
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

CPAN::Mini::Growl - Growls updates from CPAN::Mini

=head1 SYNOPSIS

  # in your crontab
  > minicpan -q -c CPAN::Mini::Growl [other minicpan options]

  # Or in ~/.minicpanrc
  class: CPAN::Mini::Growl

=head1 DESCRIPTION

CPAN::Mini::Growl is a backend class to update minicpan index but
growls distribution updates instead of printing it to the standard out
(when quiet is off). It would be useful if you run I<minicpan> in
crontab and want to be notified whenever new distributions get
mirrored onto your local CPAN mini mirror.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<minicpan> L<CPAN::Mini> L<Mac::Growl>

=cut
