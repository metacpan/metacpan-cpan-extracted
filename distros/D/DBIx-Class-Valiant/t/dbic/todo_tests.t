use Test::Most;

ok 1;

done_testing;   


__END__

=over 4

- When doing an update a default context of 'update' is added
- When doing a create a default context of 'create' is added
- basic create and create helpers (create_related, etc) tests
- basic update and update helpers (update_related, etc) tests
- other helpers such as create_or_update tests

- multicreate
  has one
  might have
  has_many
  create with mixed create/ updates on multi
  update with mixec creates/ updages on multu
  Both above with checks to make sure the correct default context is run
  Delete support
  make sure the accept_nested_for stuff works 


??many to many???


when many to many we can find on the far side of the bdir



=back


