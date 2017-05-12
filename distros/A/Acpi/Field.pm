package Acpi::Field;
use strict;

our $VERSION = '0.1';

sub new{
	my($class) = shift;
	my($self) = {};

	bless($self,$class);

	return $self;
}

sub getValueField{
        my($self,$file,$field) = @_;
        my(@ligne,@ligne2);
 
        open(FILE,$file) || die "Impossible d'ouvrir $file : $!";

        while(<FILE>){
                @ligne = split(/:/);
		if($ligne[0] eq $field){
                        $ligne[1] =~ s/^\s+//; #Delete space
                        @ligne2 = split(/\s+/,$ligne[1]);
                        close(FILE);
                        return $ligne2[0];
                }

        }

        close(FILE);
}
1;

__END__

=head1 NAME

Acpi::Field - A class to extract informations in /proc/acpi/.

=head1 SYNOPSIS

use Acpi::Field;

$field = Acpi::Field->new;

print $field->getValueField("/proc/acpi/info","version")."\n";

=head1 DESCRIPTION

Acpi::Field is used into Acpi::* to extract informations.

=head1 METHOD DESCRIPTIONS

This sections contains only the methods in Field.pm itself.

=over

=item *

new();

Contructor for the class

=item *

getValueField();

Return the value into the field.

Take 2 arg : 

=over

=item 0

The path to the file.

=item 1

The field that used to extract the value.

=back

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
