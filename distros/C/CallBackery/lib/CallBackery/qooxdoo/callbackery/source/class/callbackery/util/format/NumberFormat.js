/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

// https://en.wikipedia.org/wiki/Metric_prefix
// https://en.wikipedia.org/wiki/Binary_prefix


/**
 * A formatter and parser for numbers.
 * 
 * NOTE: Instances of this class must be disposed of after use
 *
 */
qx.Class.define("callbackery.util.format.NumberFormat", {
    extend : qx.util.format.NumberFormat,
    properties: {
        /**
         * Should large numbers be represented by their metric or binary prefix? Think 1 kg instead of 1000 g.
         */        
        unitPrefix: {
            check: ["binary","metric" ],
            init: null,
            nullable: true
        }
    },
    members: {
        format: function(num) {
            var unitPrefix = this.getUnitPrefix();
            if (unitPrefix == null){
                return this.base(arguments,num);
            }
            var bigPrefix = ['','k','M','G','T','P','E','Z','Y'];
            var smallPrefix = [ '','m','µ','n','p','f','a','z','y'];
            var base = unitPrefix === 'metric' ? 1000 : 1024;
            var power = Math.floor(Math.log(num)/Math.log(base));
            var prefix = power >= 0 ? bigPrefix[power] : smallPrefix[-power];
            num = num / Math.pow(base,power);
            var postfix = this.getPostfix() || '';
            this.setPostfix('');
            var ret = this.base(arguments,num) + " " + prefix + postfix.trim();
            this.setPostfix(postfix);
            return ret;
        },
        parse: function(str){
            var unitPrefix = this.getUnitPrefix();
            if (unitPrefix === null){
                return this.self(arguments,str); 
            }
            var prefixMap = {
                m: -1,
                µ: -2,
                n: -3,
                p: -4,
                f: -5,
                a: -6,
                z: -7,
                y: -8,
                k: 1,
                M: 2,
                G: 3,
                T: 4,
                P: 5,
                E: 6,
                Z: 7,
                Y: 8
            };
            var base = unitPrefix === 'metric' ? 1000 : 1024;
            var rx = new RegExp("^(.+?)\\s([mµnpfazykMGTPEZY])(.*)$");
            var found = rx.exec(str);
            if (found) {
                return this.base(arguments,found[1]+found[3]) 
                    * Math.pow(base,prefixMap[found[2]]);
            }
            return this.self(arguments,str);
        }
    }
}); 