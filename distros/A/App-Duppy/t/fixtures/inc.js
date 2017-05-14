function Cow() {
    this.mowed = false;
    this.moo = function moo() {
        this.mowed = true; // mootable state: don't do that at home
        return 'moo!';
    };
};
function PreCow() { 
    this.premowed = false;
    this.premoo = function premoo() {
        this.premowed = true; // mootable state: don't do that at home
        return 'Pre moo!';
    };
};

function PostCow() { 
    this.postmowed = false;
    this.postmoo = function postmoo() {
        this.postmowed = true; // mootable state: don't do that at home
        return 'Post moo!';
    };
};

