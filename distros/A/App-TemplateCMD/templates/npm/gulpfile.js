var gulp     = require('gulp');
var mocha    = require('gulp-mocha');
var istanbul = require('gulp-istanbul');
var jshint   = require('gulp-jshint');
[%- IF sonar %]
var sonar    = require('gulp-sonar');
[%- END %]
var gutil    = require('gulp-util');

gulp.task('lint', function() {
    return gulp.src('./lib/*.js')
        .pipe(jshint())
        .pipe(jshint.reporter('default'));
});

gulp.task('test', function(cb) {
    return gulp.src(['lib/*.js'])
        .pipe(istanbul())
        .pipe(istanbul.hookRequire())
        .on('finish', function () {
            gulp.src(['test/*.js'], { read: false })
                .pipe(mocha())
                .pipe(istanbul.writeReports())
                .on('error', gutil.log);
        });
});

[%- IF sonar %]
gulp.task('sonar', function () {
    var options = {
        sonar: {
            host: {
                url: 'http://localhost:9000'
            },
            jdbc: {
                url: 'jdbc:mysql://localhost:3306/sonar',
                username: 'sonar',
                password: 'sonar'
            },
            projectKey: 'sonar:node-getopt-long:0.0.1',
            projectName: 'node-getopt-long',
            projectVersion: '0.0.1',
            // comma-delimited string of source directories
            sources: 'lib',
            language: 'js',
            sourceEncoding: 'UTF-8',
            javascript: {
                lcov: {
                    reportPath: 'coverage/locv.info'
                }
            }
        }
    };

    // gulp source doesn't matter, all files are referenced in options object above
    return gulp.src('lib/getopt-long.js', { read: false })
        .pipe(sonar(options))
        .on('error', gutil.log);
});
[%- END %]

gulp.task('watch', function() {
    gulp.watch(['lib/**', 'test/**'], ['lint', 'test']);
});
