var $j = jQuery.noConflict();

$j(document).ready(function () {
    $j("#amountTip").dialog({
        autoOpen: false,
        resizable: false,
        width: 396,
        height: 58,
        title: $j("#amountTipOpener").parent().text()
    });

    $j("#tokenCustomerTip").dialog({
        autoOpen: false,
        resizable: false,
        width: 558,
        height: 58,
        title: $j("#tokenCustomerTipOpener").parent().text()
    });

    $j("#saveTokenTip").dialog({
        autoOpen: false,
        resizable: false,
        width: 578,
        height: 58,
        title: $j("#saveTokenTipOpener").parent().text()
    });

    $j("#amountTipOpener").click(function (event) {
        if ($j("#amountTip").dialog("isOpen")) {
            $j("#amountTip").dialog("close");
        }
        else {
            $j("#amountTip").dialog("option", "position", [event.clientX - 100, event.clientY]);
            $j("#amountTip").dialog("open");
        }
        return false;
    });

    $j("#tokenCustomerTipOpener").click(function (event) {
        if ($j("#tokenCustomerTip").dialog("isOpen")) {
            $j("#tokenCustomerTip").dialog("close");
        }
        else {
            $j("#tokenCustomerTip").dialog("option", "position", [event.clientX - 100, event.clientY]);
            $j("#tokenCustomerTip").dialog("open");
        }
        return false;
    });

    $j("#saveTokenTipOpener").click(function (event) {
        if ($j("#saveTokenTip").dialog("isOpen")) {
            $j("#saveTokenTip").dialog("close");
        }
        else {
            $j("#saveTokenTip").dialog("option", "position", [event.clientX - 100, event.clientY]);
            $j("#saveTokenTip").dialog("open");
        }
        return false;
    });
});