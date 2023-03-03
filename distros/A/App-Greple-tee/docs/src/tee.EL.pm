=encoding utf-8

=head1 NAME

App::Greple::tee - ενότητα για την αντικατάσταση του κειμένου που ταιριάζει με το αποτέλεσμα της εξωτερικής εντολής

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Η ενότητα B<-Mtee> του Greple στέλνει το τμήμα του κειμένου που ταιριάζει με την εντολή φίλτρου που έχει δοθεί και τα αντικαθιστά με το αποτέλεσμα της εντολής. Η ιδέα προέρχεται από την εντολή που ονομάζεται B<teip>. Είναι σαν να παρακάμπτουμε μερικά δεδομένα στην εξωτερική εντολή φίλτρου.

Η εντολή φίλτρου ακολουθεί τη δήλωση της ενότητας (C<-Mtee>) και τερματίζεται με δύο παύλες (C<-->). Για παράδειγμα, η επόμενη εντολή καλεί την εντολή C<tr> με ορίσματα C<a-z A-Z> για την αντιστοιχισμένη λέξη στα δεδομένα.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Η παραπάνω εντολή μετατρέπει όλες τις λέξεις που ταιριάζουν από πεζά σε κεφαλαία. Στην πραγματικότητα αυτό το ίδιο το παράδειγμα δεν είναι τόσο χρήσιμο επειδή η B<greple> μπορεί να κάνει το ίδιο πράγμα πιο αποτελεσματικά με την επιλογή B<--cm>.

Από προεπιλογή, η εντολή εκτελείται ως μία μόνο διεργασία και όλα τα δεδομένα που ταιριάζουν αποστέλλονται σε αυτήν αναμεμειγμένα. Αν το κείμενο που ταιριάζει δεν τελειώνει με νέα γραμμή, προστίθεται πριν και αφαιρείται μετά. Τα δεδομένα αντιστοιχίζονται γραμμή προς γραμμή, οπότε ο αριθμός των γραμμών των δεδομένων εισόδου και εξόδου πρέπει να είναι ίδιος.

Χρησιμοποιώντας την επιλογή B<--discrete>, καλείται μεμονωμένη εντολή για κάθε αντιστοιχισμένο τμήμα. Μπορείτε να καταλάβετε τη διαφορά με τις ακόλουθες εντολές.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Οι γραμμές των δεδομένων εισόδου και εξόδου δεν χρειάζεται να είναι πανομοιότυπες όταν χρησιμοποιείται η επιλογή B<--discrete>.

=head1 OPTIONS

=over 7

=item B<--discrete>

Κλήση νέας εντολής ξεχωριστά για κάθε αντιστοιχισμένο τμήμα.

=back

=head1 WHY DO NOT USE TEIP

Πρώτα απ' όλα, όποτε μπορείτε να το κάνετε με την εντολή B<teip>, χρησιμοποιήστε την. Είναι ένα εξαιρετικό εργαλείο και πολύ πιο γρήγορο από την εντολή B<greple>.

Επειδή η B<greple> έχει σχεδιαστεί για να επεξεργάζεται αρχεία εγγράφων, έχει πολλά χαρακτηριστικά που είναι κατάλληλα για αυτήν, όπως τα στοιχεία ελέγχου της περιοχής αντιστοίχισης. Ίσως αξίζει να χρησιμοποιήσετε το B<greple> για να επωφεληθείτε από αυτά τα χαρακτηριστικά.

Επίσης, το B<teip> δεν μπορεί να χειριστεί πολλαπλές γραμμές δεδομένων ως ενιαία μονάδα, ενώ το B<greple> μπορεί να εκτελέσει μεμονωμένες εντολές σε ένα κομμάτι δεδομένων που αποτελείται από πολλαπλές γραμμές.

=head1 EXAMPLE

Η επόμενη εντολή θα βρει μπλοκ κειμένου μέσα σε έγγραφο στυλ L<perlpod(1)> που περιλαμβάνεται στο αρχείο μονάδας Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Μπορείτε να τα μεταφράσετε με την υπηρεσία DeepL εκτελώντας την παραπάνω εντολή σε συνδυασμό με την ενότητα B<-Mtee> η οποία καλεί την εντολή B<deepl> ως εξής:

    greple -Mtee deepl text --to JA - -- --discrete ...

Επειδή η B<deepl> λειτουργεί καλύτερα για εισαγωγή μίας γραμμής, μπορείτε να αλλάξετε το μέρος της εντολής ως εξής:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Η ειδική ενότητα L<App::Greple::xlate::deepl> είναι όμως πιο αποτελεσματική για το σκοπό αυτό. Στην πραγματικότητα, η υπόδειξη της υλοποίησης του module B<tee> προήλθε από το module B<xlate>.

=head1 EXAMPLE 2

Η επόμενη εντολή θα βρει κάποιο εσοχές στο έγγραφο LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Μπορείτε να αναδιαμορφώσετε αυτό το τμήμα χρησιμοποιώντας την ενότητα B<tee> με την εντολή B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    
=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.03";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

our $command;
our $blockmatch;
our $discrete;

my @jammed;
my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } 0 .. $#{$argv})) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv;
    }
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    $exec->command($command)->setstdin($data)->update->data;
}

sub jammed_call {
    my @need_nl = grep { $_[$_] !~ /\n\z/ } 0 .. $#_;
    my @from = @_;
    $from[$_] .= "\n" for @need_nl;
    my @lines = map { int tr/\n/\n/ } @from;
    my $from = join '', @from;
    my $out = call $from;
    my @out = $out =~ /.*\n/g;
    if (@out < sum @lines) {
	die "Unexpected response from command:\n\n$out\n";
    }
    my @to = map { join '', splice @out, 0, $_ } @lines;
    $to[$_] =~ s/\n\z// for @need_nl;
    return @to;
}

sub postgrep {
    my $grep = shift;
    @jammed = my @block = ();
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback} ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @jammed = jammed_call @block if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @jammed // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
