package App::I18N::Command::Status;
use warnings;
use strict;
use Encode;
use Cwd;
use App::I18N::Config;
use App::I18N::Logger;
use File::Basename;
use File::Path qw(mkpath);
use File::Find::Rule;
use REST::Google::Translate;
use base qw(App::I18N::Command);


sub print_bar {
    my ($self,$value) = @_;

    my $width = 50;
    my $value_width = int($value / 100 * $width);
    my $rest_width  = $width - $value_width;

    print "[";
    print "=" x ($value_width);
    print " " x ($rest_width);
    print "]";
}

sub run {
    my $self = shift;
    my $logger = $self->logger();

    my $podir = $self->{podir};
    $podir = App::I18N->guess_podir( $self ) unless $podir;
    $self->{mo} = 1 if $self->{locale};

    print "Translation Status:\n";

    my @pofiles = File::Find::Rule->file->name( "*.po" )->in( $podir );
    for my $pofile ( @pofiles ) {
        my $extract = Locale::Maketext::Extract->new;

        my $lang;
        if( $self->{locale} ) {
            ($lang) = ($pofile =~ m{(\w+)/LC_MESSAGES/} );   # get en_US or zh_TW ... etc
        } else {
            ($lang) = ($pofile =~ m{(\w+)\.po$} );   # get en_US or zh_TW ... etc
        }

        $extract->read_po($pofile);

        my $lexicon = $extract->lexicon;

        my $total = scalar keys %$lexicon;
        my $empty = scalar grep { $_ } values %$lexicon;
        my $percent = $empty / $total * 100;

        printf "%10s: ", $lang;
        $self->print_bar( $percent );
        printf " %2d%% (%d/%d) ", $percent, $empty, $total;
        print "\n";
    }
}



1;
__END__
=head1 NAME

App::I18N::Command::status - Show translation status

=head1 USAGE

    po status

=cut
