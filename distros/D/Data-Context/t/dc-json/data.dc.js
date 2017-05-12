{
    "TYPE"   : "DEFAULT",  # end of line comment
    "basic"  : "text",
    "number" : 25,
    "hash"   : {
        # nested comment
        "content" : {
            "METHOD" : "expand_vars",
            "value"  : "test.value.0",
        },
        "straight_var" : "#test.value.1#",
        "longrunning" : {
            "MODULE" : "main",
            "url" : "http://slashdot.org/",
        },
        "shortrunning" : {
            "MODULE" : "main",
            "url" : "http://www.google.com/",
        },
    },
    "list" : [
        "one",
        "two"
    ],
}
