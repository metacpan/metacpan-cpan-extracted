% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%== $p->{fullName} %> <<%= $p->{email} %>>
 *********************************************************************** */

/**
 * Main application class.
 * @asset(<%= $p->{name} %>/*)
 *
 */
qx.Class.define("<%= $p->{name} %>.Application", {
    extend : callbackery.Application,
    members : {
        main : function() {
            // Call super class
            this.base(arguments);
        }
    }
});
