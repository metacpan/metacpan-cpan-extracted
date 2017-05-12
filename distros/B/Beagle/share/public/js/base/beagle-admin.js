/*
 * Beagle JavaScript Library
 *
 * Copyright 2011, sunnavy@gmail.com
 * licensed under the GPL Version 2.
 */

function beagleBindKeys () {
    $('textarea').keydown(function (e) {
        if ( e.keyCode == 13 && e.ctrlKey ) {
            $(this).closest('form').submit();
        }
    } );
}

function beagleInitAjaxDeleteEntry () {
    $('a.delete-entry').click(
        function () {
            var e = $(this);
            var id = e.attr('name');
            $.ajax( {
            url: beaglePrefix + 'admin/entry/delete',
            dataType: 'json',
            type: 'post',
            data: { id: id },
            success: function( json, status, xhr ) {
                if ( json && json.status == 'deleted' ) {
                    if ( window.location.pathname.match(/admin\/entries/ ) ) {
                        e.closest('li').remove();
                        beagleContrast(e.closest('ul'));
                    }
                    else if ( window.location.pathname.match(/admin\/entry/ ) ) {
                        window.location = beaglePrefix+'admin/entries';
                    }
                    else {
                        $('#'+id).remove();
                        if ( json.redraw_menu ) {
                            $('#menu').load(beaglePrefix + 'fragment/menu', function () {
                                beagleContrast('#menu');
                            } );
                        }
                        beagleContrast(e.closest('div.comments'));
                    }
                }
            }
            } );
            return false;
        }
    );
}

function beagleInitAjaxCreateComment ( ) {
    $('form.create-comment').ajaxForm(
            {
                beforeSubmit: function (arr,form) {
                    var e = form.find('textarea');
                    if ( beagleIsEmpty( e ) ) {
                        return false;
                    }
                    else {
                        return true;
                    }
                },
                url: "/admin/entry/comment/new",
                dataType: 'json',
                type: 'post',
                success: function(json, status, xhr, form ) {
                    form.submitted = false;
                    if ( json ) {

                        if ( json.status == 'created' ) {
                            var str = json.content;
                            form.find('textarea').val('');
                            var parent = form.closest('div.comments').children('div.content');
                            parent.append(str);
                            beagleContrast(parent);
                            var comments =
                                form.closest('div.comments').children('div.content');
                            if ( comments.is(':not(:visible)') ) {
                                comments.show();
                            }
                            return true;
                        }
                        else {
                            alert( json.status );
                        }
                    }
                },
            }
    );
}

function beagleAdminInit ( ) {

    $('select[name=format]').change( function() {
        var val = $('select[name=format]').val();
        var e = $(this).closest('form').find('textarea');
        var form = $(this).closest('form');
        if ( val == 'wiki' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( wikiSettings );
            }
        }
        else if ( val == 'markdown' ) {
            if ( !form.find('div.markItUp').length ) {
                e.markItUp( markdownSettings );
            }
        }
        else {
            e.markItUpRemove();
        }
    });


    beagleInitAjaxCreateComment();
    beagleInitAjaxDeleteEntry();
    beagleBindKeys();

    $('textarea.markitup.wiki').markItUp( wikiSettings );
    $('textarea.markitup.markdown').markItUp( markdownSettings );

    $('input.attach-more').click( function() {
        var att = $(this).closest('form').find('div.attach').first().clone();
        var p = $(this).closest('div.wrapper');
        p.before(att);
        return false;
    } );

    $('div.hover.create-entry' ).hoverIntent(
    {
        timeout: 500,
        over: function () {
            $(this).children('ul').show();
        },
        out: function () { $(this).children('ul').hide(); }
    }
    );
}

