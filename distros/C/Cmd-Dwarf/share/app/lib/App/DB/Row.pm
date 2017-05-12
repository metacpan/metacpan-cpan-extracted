package App::DB::Row;
use Dwarf::Pragma;
use parent 'Teng::Row';
use Class::Method::Modifiers;

before update => \&will_update;
sub will_update {
	my ($self, $update_row_data) = @_;
	my $table = $self->{table};
	if (grep /^updated_at$/, @{ $table->columns }) {
		$update_row_data->{updated_at} ||= \'NOW()';
	}
}

1;