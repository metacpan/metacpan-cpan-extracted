/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * licensed under GPL Version 2.
 */

beaglePrefix = "/";

function beagleContrast (p) {
    if ( !p ) {
        p = 'body';
    }
    $(p).find('.contrast').removeClass('odd even');
    $(p).find('.contrast:odd').addClass('odd');
    $(p).find('.contrast:even').addClass('even');
}

function beagleIsEmpty ( e ) {
    var v = e.val();
    if ( v == '' || v == e.attr('placeholder') ) {
        return true;
    }

    if ( v.match(/\S/) ) {
        return false;
    }
    return true;
}

function beagleIsInRange ( e, start, end ) {
    var l = e.val().length;
    return l >= start && l <= end;
}

function beagleToggle ( ) {
    if ( $(this).parent().children('ul:not(:hidden)').length ) {
        $(this).parent().children('ul:not(:hidden)').hide();
        $(this).html('+');
    }
    else {
        $(this).parent().children('ul:hidden').show();
        $(this).html('-');
    }
}

function beagleHoverTag ( ) {
    $('td.hover.tag' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            var glance = $(this).children( 'div.glance' ).first();
            if ( glance ) {
                if ( glance.text() == '' ) {
                    var name = $(this).find('a').first().attr('name');
                    if ( name ) {
                        $.get(beaglePrefix + 'fragment/tag/' + name, function ( data ) {
                            glance.html(data);
                            glance.find('div.list > div').css('margin-top', '0.25em');
                            glance.show();
                            return;
                        } );
                    }
                }
                else {
                    glance.show();
                }
            }
        },
        out: function () { $(this).children( 'div.glance' ).hide(); }
    }
    );

    $('li.hover.tag a.hover, li.hover.tag > ul' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).closest('li.hover.tag').children('ul').show();
        },
        out: function () {}
    }
    );

    $('li.hover.tag').hoverIntent( {
        timeout: 500,
        over: function () {},
        out: function () { $(this).children('ul').hide(); } } );
}

function beagleHoverArchive ( ) {
    $('td.hover.archive, div.hover.archive' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            var glance = $(this).children( 'div.glance' ).first();
            if ( glance ) {
                if ( glance.text() == '' ) {
                    var name = $(this).find('a').first().attr('name');
                    if ( name ) {
                        $.get(beaglePrefix + 'fragment/archive/' + name, function ( data ) {
                            glance.html(data);
                            glance.find('div.list > div').css('margin-top', '0.25em');
                            glance.show();
                            return;
                        } );
                    }
                }
                else {
                    glance.show();
                }
            }
        },
        out: function () { $(this).children( 'div.glance' ).hide(); }
    }
    );

    $('li.hover.archive' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).children('ul').show();
        },
        out: function () { $(this).children('ul').hide(); }
    }
    );
}

function beagleSetName ( name, e ) {
    if ( ! e ) {
        e = $('div.hover.names').find('a[name=' + name + ']');
    }

    var show = $('div.hover.names').children('a').first();

    if ( e ) {
        $(e).closest('ul').find('a').css('opacity', 0.7).removeClass('selected');
        $(e).css('opacity', 1).addClass('selected');
        if ( show ) {
            show.text(name);
        }
    }
}

function beagleName ( ) {
    var name = $('div.name').first().text();
    if ( name ) {
        beagleSetName(name);
    }

    $('div.hover.names' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).children('ul').show();
        },
        out: function () { $(this).children('ul').hide(); }
    }
    );
}

function beagleSetWidth ( width, e ) {
    $('body').css('width', width+'%');
    if ( ! e ) {
        e = $('div.hover.set-width').find('a[name=' + width + ']');
    }

    var show = $('div.hover.set-width').children('a').first();

    if ( e ) {
        $(e).closest('ul').find('a').css('opacity', 0.7).removeClass('selected');
        $(e).css('opacity', 1).addClass('selected');
        if ( show ) {
            show.text(width+'%');
        }
    }
    $.cookie('width', width);
}

function beagleWidth ( ) {
    var width = $.cookie('width') || 100;
    beagleSetWidth( width );

    $('div.hover.set-width' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).children('ul').show();
        },
        out: function () { $(this).children('ul').hide(); }
    }
    );

    $('div.hover.set-width ul a' ).click( function () {
        var width = parseInt($(this).attr('name'));
        if ( width ) {
            beagleSetWidth(width, this);
        }
        return false;
    } );

    $('div.hover.set-width a').hoverIntent ( {
        timeout: 500,
        over: function () {
            var width = parseInt($(this).attr('name'));
            if ( width ) {
                beagleSetWidth(width, this);
            }
            return false;
        },
        out: function() {}
    } );
}


function beagleInit ( opts ) {
    prettyPrint();
    beaglePrefix = $('div.beagle').children('span[name=prefix]').text() || '/';

    $('a.toggle.hide').click(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').hide();
            $(this).hide();
            $(this).siblings('a.toggle.show').show();
            return false;
        }
    );
    $('a.toggle.show').click(
        function() {
            $(this).closest('div:has("div.content")').children('div.content').show();
            $(this).hide();
            $(this).siblings('a.toggle.hide').show();
            return false;
        }
    );

    $('a.comments-toggle').click(
        function() {
            var comments =
                $(this).closest('div.comments').children('div.content');
            if ( comments.is(':visible') ) {
                comments.hide();
            }
            else {
                comments.show();
            }
            return false;
        }
    );
    $('div.attachments div.preview img').hoverIntent ( {
        timeout: 500,
        over: function () { $(this).css('width', '50%');},
        out: function () { $(this).css('width', '10%'); }
    } );

    beagleContrast();
    beagleHoverTag();
    beagleHoverArchive();

    beagleWidth();
    beagleName();

    $('div.message').delay(3000).fadeOut('slow');

}

