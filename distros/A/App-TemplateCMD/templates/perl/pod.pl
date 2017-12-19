[% IF not vars %][% vars = [ 'var1', 'var2' ] %][% END -%]
=head3 C<[% sub || 'sub' %] ( [% FOREACH var = vars %]$[% var %],[% END %] )>
[% FOREACH var = vars %]
Param: C<$[% var %]> - type (detail) - description
[% END -%]

Return: [% return %] -

Description:

=cut
