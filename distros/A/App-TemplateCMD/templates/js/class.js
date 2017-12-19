[% IF not class %][% class = 'Class' %][% END -%]
[% IF not parent %][% parent = 'Object' %][% END -%]
[% IF not params %][% params = [ 'r1', 'r2' ] %][% END -%]
[% IF not licence %][% licence = 'gpl' %][% END -%]
[% IF not functions %][% functions = ['example'] %][% END -%]
[% INCLUDE js/jdoc/class.js %]
/*
[%- INCLUDE licence.txt -%]
*/

[% class %].prototype             = new [% parent %]();
[% class %].prototype.constructor = [% class %];
[% class %].superclass            = [% parent %].prototype;
[% INCLUDE js/jdoc/func.js description => 'object creator' -%]
function [% class %]( [% FOREACH param = params %][% param %], [% END %] ) {
    if ( arguments.length > 0 ) this.init( '[% class %]', [% FOREACH param = params %][% param %], [% END %] );
}

/**
 *  @param  class_name: The name of the class instantiating this object.
[% INCLUDE js/jdoc/params.js -%]
 *
 *  The [% class %] object initialiser
 */
[% class %].prototype.init = function( class_name, [% FOREACH param = params %][% param %], [% END %] ) {

    // init the parent class
    [% class %].superclass.init.call( this, class_name );

    this.bodyid = bodyid;
}
[% FOREACH method = functions %]
[% INCLUDE js/method.js %]
[% END -%]
