package PackedCounter;

use strict;
use warnings;
use Chandra::App;

my $count = 0;

sub run {
    my $app = Chandra::App->new(
        title  => 'Counter',
        width  => 400,
        height => 350,
    );

    $app->bind('increment', sub {
        $count++;
        return $count;
    });

    $app->bind('decrement', sub {
        $count--;
        return $count;
    });

    $app->bind('reset', sub {
        $count = 0;
        return $count;
    });

    $app->bind('get_count', sub {
        return $count;
    });

    $app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: #fff;
    }
    .counter {
        text-align: center;
        background: rgba(255,255,255,0.15);
        backdrop-filter: blur(10px);
        border-radius: 20px;
        padding: 40px 60px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.2);
    }
    h1 { font-size: 18px; opacity: 0.9; margin-bottom: 20px; }
    #count {
        font-size: 72px;
        font-weight: 700;
        margin: 20px 0;
        transition: transform 0.15s ease;
    }
    #count.bump { transform: scale(1.2); }
    .buttons { display: flex; gap: 12px; justify-content: center; margin-top: 20px; }
    button {
        width: 50px; height: 50px;
        border-radius: 50%;
        border: 2px solid rgba(255,255,255,0.5);
        background: rgba(255,255,255,0.2);
        color: #fff;
        font-size: 24px;
        cursor: pointer;
        transition: all 0.15s ease;
    }
    button:hover { background: rgba(255,255,255,0.35); transform: scale(1.1); }
    button:active { transform: scale(0.95); }
    .reset {
        margin-top: 16px;
        width: auto;
        border-radius: 8px;
        padding: 8px 24px;
        font-size: 14px;
    }
</style>
</head>
<body>
    <div class="counter">
        <h1>Perl Counter</h1>
        <div id="count">0</div>
        <div class="buttons">
            <button onclick="dec()">−</button>
            <button onclick="inc()">+</button>
        </div>
        <button class="reset" onclick="reset()">Reset</button>
    </div>
    <script>
        function update(val) {
            var el = document.getElementById('count');
            el.textContent = val;
            el.classList.add('bump');
            setTimeout(function(){ el.classList.remove('bump'); }, 150);
        }
        function inc() {
            window.chandra.invoke('increment', []).then(update);
        }
        function dec() {
            window.chandra.invoke('decrement', []).then(update);
        }
        function reset() {
            window.chandra.invoke('reset', []).then(update);
        }
    </script>
</body>
</html>
HTML

    $app->run;
}

1;
