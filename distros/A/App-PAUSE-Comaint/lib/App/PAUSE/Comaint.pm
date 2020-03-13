package App::PAUSE::Comaint;

use strict;
use 5.008_001;
our $VERSION = '0.08';

use App::PAUSE::Comaint::PackageScanner;
use WWW::Mechanize;
use ExtUtils::MakeMaker qw(prompt);

sub new {
    my($class) = @_;
    bless { mech => WWW::Mechanize->new }, $class;
}

sub mech { $_[0]->{mech} }

sub run {
    my($self, $module, $comaint) = @_;

    unless ($module && $comaint) {
        die "Usage: comaint Module AUTHOR\n";
    }

    if ($module =~ /^[A-Z]+$/ && $comaint =~ /::/) {
        die "Usage: comaint Module AUTHOR\n";
    }

    my $scanner = App::PAUSE::Comaint::PackageScanner->new('http://cpanmetadb.plackperl.org');
    my @packages = $scanner->find($module);

    @packages or die "Couldn't find module '$module' in 02packages\n";

    $self->login_pause;
    $self->make_comaint($comaint, \@packages);
}

sub get_credentials {
    my $self = shift;

    my %rc;
    my $file = "$ENV{HOME}/.pause";
    if (eval { require Config::Identity }) {
        %rc = Config::Identity->load($file);
    } else {
        open my $in, "<", $file
            or die "Can't open $file: $!";
        while (<$in>) {
            /^(\S+)\s+(.*)/ and $rc{$1} = $2;
        }
    }

    return @rc{qw(user password)};
}

sub login_pause {
    my $self = shift;

    $self->mech->credentials($self->get_credentials);
    $self->mech->get("https://pause.perl.org/pause/authenquery?ACTION=share_perms");

    $self->mech->form_number(1);
    $self->mech->click('weaksubmit_pause99_share_perms_makeco');

    $self->mech->content =~ /Select a co-maintainer/
        or die "Something is wrong with Screen-scraping: ", $self->mech->content;
}

sub make_comaint {
    my($self, $author, $packages) = @_;

    my %try = map { $_ => 1 } @$packages;

    my $form = $self->mech->form_number(1);

    for my $input ($form->find_input('pause99_share_perms_makeco_m')) {
        my $value = ($input->possible_values)[1];
        if ($try{$value}) {
            $input->check;
            delete $try{$value};
        }
    }

    if (keys %try) {
        my $msg = "You don't seem to be a primary maintainer of the following modules:\n";
        for my $module (sort keys %try) {
            $msg .= "  $module\n";
        }
        die $msg;
    }

    $form->find_input("pause99_share_perms_makeco_a")->value($author);

    print "Going to make $author as a comaint of the following modules.\n\n";
    for my $package (@$packages) {
        print "  $package\n";
    }
    print "\n";

    my $value = prompt "Are you sure?", "y";
    return if lc($value) ne 'y';

    $self->mech->click_button(value => 'Make Co-Maintainer');

    if (my @results = ($self->mech->content =~ /<p class="(?:result|warning)">(Added .*? to co-maint.*?|\w+ was already a co-maint.*?: skipping)<\/p>/g)) {
        print "\n", join("\n", @results), "\n";
    } else {
        warn "Something's wrong: ", $self->mech->content;
    }
}


1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::PAUSE::Comaint - Make someone co-maint of your module on PAUSE/CPAN

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2013- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<comaint>

=cut
