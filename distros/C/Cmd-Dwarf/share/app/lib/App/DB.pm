package App::DB;
use Dwarf::Pragma;
use parent 'Teng';
use Class::Method::Modifiers;
use DateTime;
use DateTime::Format::Pg;

#__PACKAGE__->load_plugin('BulkInsert');
__PACKAGE__->load_plugin('Count');

before insert      => \&will_insert;
before fast_insert => \&will_insert;
sub will_insert {
	my ($self, $table_name, $row_data) = @_;
	my $table = $self->schema->get_table($table_name);
	if (grep /^created_at$/, @{ $table->columns }) {
		$row_data->{created_at} ||= \'NOW()';
	}
	if (grep /^updated_at$/, @{ $table->columns }) {
		$row_data->{updated_at} ||= \'NOW()';
	}
}

before update => \&will_update;
sub will_update {
	my ($self, $table_name, $update_row_data, $update_condition) = @_;
	my $table = $self->schema->get_table($table_name);
	if (grep /^updated_at$/, @{ $table->columns }) {
		$update_row_data->{updated_at} ||= \'NOW()';
	}
}

sub inflate_dt {
	my ($self, $value) = @_;
	return unless defined $value;
	my $dt = DateTime::Format::Pg->parse_datetime($value);
	$dt->set_time_zone('Asia/Tokyo');
	return $dt;
}

sub deflate_dt {
	my ($self, $dt) = @_;
	return if ref $dt ne 'DateTime';
	return sprintf "%s %s", $dt->ymd('-'), $dt->hms;
}

1;
