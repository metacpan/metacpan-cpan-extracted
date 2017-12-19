[% UNLESS params %][% params = ['parameter'] %][% END -%]
[% FOREACH param = params -%]
 *  @param [% param %]:
[% END -%]
