#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_githubcl() {

    COMPREPLY=()
    local program=githubcl
    local cur=${COMP_WORDS[$COMP_CWORD]}
#    echo "COMP_CWORD:$COMP_CWORD cur:$cur" >>/tmp/comp
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr $COMP_CWORD - 1`
    MYWORDS=("${COMP_WORDS[@]:1:$COMP_CWORD}")

    FLAGS=('--debug' 'debug' '-d' 'debug' '--verbose' 'verbose' '-v' 'verbose' '--help' 'Show command help' '-h' 'Show command help')
    OPTIONS=('--data-file' 'File with data for POST/PUT/PATCH/DELETE requests')
    __githubcl_handle_options_flags

    case $INDEX in

    0)
        __comp_current_options || return
        __githubcl_dynamic_comp 'commands' 'DELETE'$'\t''DELETE call'$'\n''GET'$'\t''GET call'$'\n''PATCH'$'\t''PATCH call'$'\n''POST'$'\t''POST call'$'\n''PUT'$'\t''PUT call'$'\n''help'$'\t''Show command help'

    ;;
    *)
    # subcmds
    case ${MYWORDS[0]} in
      DELETE)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' '/gists/:id'$'\t''Delete a gist.'$'\n''/gists/:id/comments/:commentId'$'\t''Delete a comment.'$'\n''/gists/:id/star'$'\t''Unstar a gist.'$'\n''/notifications/threads/:id/subscription'$'\t''Delete a Thread Subscription.'$'\n''/orgs/:org/members/:username'$'\t''Remove a member.'$'\n''/orgs/:org/public_members/:username'$'\t''Conceal a user'"'"'s membership.'$'\n''/repos/:owner/:repo'$'\t''Delete a Repository.'$'\n''/repos/:owner/:repo/collaborators/:user'$'\t''Remove collaborator.'$'\n''/repos/:owner/:repo/comments/:commentId'$'\t''Delete a commit comment'$'\n''/repos/:owner/:repo/contents/:path'$'\t''Delete a file.'$'\n''/repos/:owner/:repo/downloads/:downloadId'$'\t''Deprecated. Delete a download.'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\t''Delete a Reference'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\t''Delete a hook.'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\t''Remove all labels from an issue....'$'\n''/repos/:owner/:repo/issues/:number/labels/:name'$'\t''Remove a label from an issue.'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\t''Delete a comment.'$'\n''/repos/:owner/:repo/keys/:keyId'$'\t''Delete a key.'$'\n''/repos/:owner/:repo/labels/:name'$'\t''Delete a label.'$'\n''/repos/:owner/:repo/milestones/:number'$'\t''Delete a milestone.'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\t''Delete a comment.'$'\n''/repos/:owner/:repo/releases/:id'$'\t''Users with push access to the repository can delet...'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\t''Delete a release asset'$'\n''/repos/:owner/:repo/subscription'$'\t''Delete a Repository Subscription....'$'\n''/teams/:teamId'$'\t''Delete team.'$'\n''/teams/:teamId/members/:username'$'\t''The "Remove team member" API is deprecated and is ...'$'\n''/teams/:teamId/memberships/:username'$'\t''Remove team membership.'$'\n''/teams/:teamId/repos/:owner/:repo'$'\t''In order to remove a repository from a team, the a...'$'\n''/user/emails'$'\t''Delete email address(es).'$'\n''/user/following/:username'$'\t''Unfollow a user.'$'\n''/user/keys/:keyId'$'\t''Delete a public key. Removes a public key. Require...'$'\n''/user/starred/:owner/:repo'$'\t''Unstar a repository'$'\n''/user/subscriptions/:owner/:repo'$'\t''Stop watching a repository'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          /gists/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/star)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications/threads/:id/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/public_members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/collaborators/:user)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/contents/:path)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/downloads/:downloadId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/refs/:ref)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks/:hookId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/labels/:name)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              5)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/keys/:keyId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/labels/:name)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/assets/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/memberships/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/repos/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/emails)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/following/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/keys/:keyId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/starred/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/subscriptions/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      GET)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' '/emojis'$'\t''Lists all the emojis available to use on GitHub....'$'\n''/events'$'\t''List public events.'$'\n''/feeds'$'\t''List Feeds.'$'\n''/gists'$'\t''List the authenticated user'"'"'s gists or if called a...'$'\n''/gists/:id'$'\t''Get a single gist.'$'\n''/gists/:id/comments'$'\t''List comments on a gist.'$'\n''/gists/:id/comments/:commentId'$'\t''Get a single comment.'$'\n''/gists/:id/star'$'\t''Check if a gist is starred.'$'\n''/gists/public'$'\t''List all public gists.'$'\n''/gists/starred'$'\t''List the authenticated user'"'"'s starred gists....'$'\n''/gitignore/templates'$'\t''Listing available templates.'$'\n''/gitignore/templates/:language'$'\t''Get a single template.'$'\n''/issues'$'\t''List issues.'$'\n''/legacy/issues/search/:owner/:repository/:state/:keyword'$'\t''Find issues by state and keyword....'$'\n''/legacy/repos/search/:keyword'$'\t''Find repositories by keyword. Note, this legacy me...'$'\n''/legacy/user/email/:email'$'\t''This API call is added for compatibility reasons o...'$'\n''/legacy/user/search/:keyword'$'\t''Find users by keyword.'$'\n''/meta'$'\t''This gives some information about GitHub.com, the ...'$'\n''/networks/:owner/:repo/events'$'\t''List public events for a network of repositories....'$'\n''/notifications'$'\t''List your notifications.'$'\n''/notifications/threads/:id'$'\t''View a single thread.'$'\n''/notifications/threads/:id/subscription'$'\t''Get a Thread Subscription.'$'\n''/orgs/:org'$'\t''Get an Organization.'$'\n''/orgs/:org/events'$'\t''List public events for an organization....'$'\n''/orgs/:org/issues'$'\t''List issues.'$'\n''/orgs/:org/members'$'\t''Members list.'$'\n''/orgs/:org/members/:username'$'\t''Check if a user is, publicly or privately, a membe...'$'\n''/orgs/:org/public_members'$'\t''Public members list.'$'\n''/orgs/:org/public_members/:username'$'\t''Check public membership.'$'\n''/orgs/:org/repos'$'\t''List repositories for the specified org....'$'\n''/orgs/:org/teams'$'\t''List teams.'$'\n''/rate_limit'$'\t''Get your current rate limit status...'$'\n''/repos/:owner/:repo'$'\t''Get repository.'$'\n''/repos/:owner/:repo/:archive_format/:path'$'\t''Get archive link.'$'\n''/repos/:owner/:repo/assignees'$'\t''List assignees.'$'\n''/repos/:owner/:repo/assignees/:assignee'$'\t''Check assignee.'$'\n''/repos/:owner/:repo/branches'$'\t''Get list of branches'$'\n''/repos/:owner/:repo/branches/:branch'$'\t''Get Branch'$'\n''/repos/:owner/:repo/collaborators'$'\t''List.'$'\n''/repos/:owner/:repo/collaborators/:user'$'\t''Check if user is a collaborator...'$'\n''/repos/:owner/:repo/comments'$'\t''List commit comments for a repository....'$'\n''/repos/:owner/:repo/comments/:commentId'$'\t''Get a single commit comment.'$'\n''/repos/:owner/:repo/commits'$'\t''List commits on a repository.'$'\n''/repos/:owner/:repo/commits/:ref/status'$'\t''Get the combined Status for a specific Ref...'$'\n''/repos/:owner/:repo/commits/:shaCode'$'\t''Get a single commit.'$'\n''/repos/:owner/:repo/commits/:shaCode/comments'$'\t''List comments for a single commitList comments for...'$'\n''/repos/:owner/:repo/compare/:baseId...:headId'$'\t''Compare two commits'$'\n''/repos/:owner/:repo/contents/:path'$'\t''Get contents.'$'\n''/repos/:owner/:repo/contributors'$'\t''Get list of contributors.'$'\n''/repos/:owner/:repo/deployments'$'\t''Users with pull access can view deployments for a ...'$'\n''/repos/:owner/:repo/deployments/:id/statuses'$'\t''Users with pull access can view deployment statuse...'$'\n''/repos/:owner/:repo/downloads'$'\t''Deprecated. List downloads for a repository....'$'\n''/repos/:owner/:repo/downloads/:downloadId'$'\t''Deprecated. Get a single download....'$'\n''/repos/:owner/:repo/events'$'\t''Get list of repository events.'$'\n''/repos/:owner/:repo/forks'$'\t''List forks.'$'\n''/repos/:owner/:repo/git/blobs/:shaCode'$'\t''Get a Blob.'$'\n''/repos/:owner/:repo/git/commits/:shaCode'$'\t''Get a Commit.'$'\n''/repos/:owner/:repo/git/refs'$'\t''Get all References'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\t''Get a Reference'$'\n''/repos/:owner/:repo/git/tags/:shaCode'$'\t''Get a Tag.'$'\n''/repos/:owner/:repo/git/trees/:shaCode'$'\t''Get a Tree.'$'\n''/repos/:owner/:repo/hooks'$'\t''Get list of hooks.'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\t''Get single hook.'$'\n''/repos/:owner/:repo/issues'$'\t''List issues for a repository.'$'\n''/repos/:owner/:repo/issues/:number'$'\t''Get a single issue'$'\n''/repos/:owner/:repo/issues/:number/comments'$'\t''List comments on an issue.'$'\n''/repos/:owner/:repo/issues/:number/events'$'\t''List events for an issue.'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\t''List labels on an issue.'$'\n''/repos/:owner/:repo/issues/comments'$'\t''List comments in a repository.'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\t''Get a single comment.'$'\n''/repos/:owner/:repo/issues/events'$'\t''List issue events for a repository....'$'\n''/repos/:owner/:repo/issues/events/:eventId'$'\t''Get a single event.'$'\n''/repos/:owner/:repo/keys'$'\t''Get list of keys.'$'\n''/repos/:owner/:repo/keys/:keyId'$'\t''Get a key'$'\n''/repos/:owner/:repo/labels'$'\t''List all labels for this repository....'$'\n''/repos/:owner/:repo/labels/:name'$'\t''Get a single label.'$'\n''/repos/:owner/:repo/languages'$'\t''List languages.'$'\n''/repos/:owner/:repo/milestones'$'\t''List milestones for a repository....'$'\n''/repos/:owner/:repo/milestones/:number'$'\t''Get a single milestone.'$'\n''/repos/:owner/:repo/milestones/:number/labels'$'\t''Get labels for every issue in a milestone....'$'\n''/repos/:owner/:repo/notifications'$'\t''List your notifications in a repository...'$'\n''/repos/:owner/:repo/pulls'$'\t''List pull requests.'$'\n''/repos/:owner/:repo/pulls/:number'$'\t''Get a single pull request.'$'\n''/repos/:owner/:repo/pulls/:number/comments'$'\t''List comments on a pull request....'$'\n''/repos/:owner/:repo/pulls/:number/commits'$'\t''List commits on a pull request....'$'\n''/repos/:owner/:repo/pulls/:number/files'$'\t''List pull requests files.'$'\n''/repos/:owner/:repo/pulls/:number/merge'$'\t''Get if a pull request has been merged....'$'\n''/repos/:owner/:repo/pulls/comments'$'\t''List comments in a repository.'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\t''Get a single comment.'$'\n''/repos/:owner/:repo/readme'$'\t''Get the README.'$'\n''/repos/:owner/:repo/releases'$'\t''Users with push access to the repository will rece...'$'\n''/repos/:owner/:repo/releases/:id'$'\t''Get a single release'$'\n''/repos/:owner/:repo/releases/:id/assets'$'\t''List assets for a release'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\t''Get a single release asset'$'\n''/repos/:owner/:repo/stargazers'$'\t''List Stargazers.'$'\n''/repos/:owner/:repo/stats/code_frequency'$'\t''Get the number of additions and deletions per week...'$'\n''/repos/:owner/:repo/stats/commit_activity'$'\t''Get the last year of commit activity data....'$'\n''/repos/:owner/:repo/stats/contributors'$'\t''Get contributors list with additions, deletions, a...'$'\n''/repos/:owner/:repo/stats/participation'$'\t''Get the weekly commit count for the repo owner and...'$'\n''/repos/:owner/:repo/stats/punch_card'$'\t''Get the number of commits per hour in each day....'$'\n''/repos/:owner/:repo/statuses/:ref'$'\t''List Statuses for a specific Ref....'$'\n''/repos/:owner/:repo/subscribers'$'\t''List watchers.'$'\n''/repos/:owner/:repo/subscription'$'\t''Get a Repository Subscription.'$'\n''/repos/:owner/:repo/tags'$'\t''Get list of tags.'$'\n''/repos/:owner/:repo/teams'$'\t''Get list of teams'$'\n''/repos/:owner/:repo/watchers'$'\t''List Stargazers. New implementation....'$'\n''/repositories'$'\t''List all public repositories.'$'\n''/search/code'$'\t''Search code.'$'\n''/search/issues'$'\t''Find issues by state and keyword. (This method ret...'$'\n''/search/repositories'$'\t''Search repositories.'$'\n''/search/users'$'\t''Search users.'$'\n''/teams/:teamId'$'\t''Get team.'$'\n''/teams/:teamId/members'$'\t''List team members.'$'\n''/teams/:teamId/members/:username'$'\t''The "Get team member" API is deprecated and is sch...'$'\n''/teams/:teamId/memberships/:username'$'\t''Get team membership.'$'\n''/teams/:teamId/repos'$'\t''List team repos'$'\n''/teams/:teamId/repos/:owner/:repo'$'\t''Check if a team manages a repository...'$'\n''/user'$'\t''Get the authenticated user.'$'\n''/user/emails'$'\t''List email addresses for a user....'$'\n''/user/followers'$'\t''List the authenticated user'"'"'s followers...'$'\n''/user/following'$'\t''List who the authenticated user is following....'$'\n''/user/following/:username'$'\t''Check if you are following a user....'$'\n''/user/issues'$'\t''List issues.'$'\n''/user/keys'$'\t''List your public keys.'$'\n''/user/keys/:keyId'$'\t''Get a single public key.'$'\n''/user/orgs'$'\t''List public and private organizations for the auth...'$'\n''/user/repos'$'\t''List repositories for the authenticated user. Note...'$'\n''/user/starred'$'\t''List repositories being starred by the authenticat...'$'\n''/user/starred/:owner/:repo'$'\t''Check if you are starring a repository....'$'\n''/user/subscriptions'$'\t''List repositories being watched by the authenticat...'$'\n''/user/subscriptions/:owner/:repo'$'\t''Check if you are watching a repository....'$'\n''/user/teams'$'\t''List all of the teams across all of the organizati...'$'\n''/users'$'\t''Get all users.'$'\n''/users/:username'$'\t''Get a single user.'$'\n''/users/:username/events'$'\t''If you are authenticated as the given user, you wi...'$'\n''/users/:username/events/orgs/:org'$'\t''This is the user'"'"'s organization dashboard. You mus...'$'\n''/users/:username/followers'$'\t''List a user'"'"'s followers'$'\n''/users/:username/following/:targetUser'$'\t''Check if one user follows another....'$'\n''/users/:username/gists'$'\t''List a users gists.'$'\n''/users/:username/keys'$'\t''List public keys for a user.'$'\n''/users/:username/orgs'$'\t''List all public organizations for a user....'$'\n''/users/:username/received_events'$'\t''These are events that you'"'"'ll only see public event...'$'\n''/users/:username/received_events/public'$'\t''List public events that a user has received...'$'\n''/users/:username/repos'$'\t''List public repositories for the specified user....'$'\n''/users/:username/starred'$'\t''List repositories being starred by a user....'$'\n''/users/:username/subscriptions'$'\t''List repositories being watched by a user....'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          /emojis)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /feeds)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /gists)
            FLAGS+=()
            OPTIONS+=('--q-since' 'Timestamp in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ.
Only gists updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/star)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/public)
            FLAGS+=()
            OPTIONS+=('--q-since' 'Timestamp in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ.
Only gists updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/starred)
            FLAGS+=()
            OPTIONS+=('--q-since' 'Timestamp in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ.
Only gists updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /gitignore/templates)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /gitignore/templates/:language)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /issues)
            FLAGS+=()
            OPTIONS+=('--q-filter' 'Issues assigned to you / created by you / mentioning you / you'"'"'re
subscribed to updates for / All issues the authenticated user can see
' '--q-state' '' '--q-labels' 'String list of comma separated Label names. Example - bug,ui,@high.' '--q-sort' '' '--q-direction' '' '--q-since' 'Optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Only issues updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-filter)
                    _githubcl_compreply "'assigned'"$'\n'"'created'"$'\n'"'mentioned'"$'\n'"'subscribed'"$'\n'"'all'"
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-labels)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"$'\n'"'comments'"
                  ;;
                  --q-direction)
                    _githubcl_compreply "'asc'"$'\n'"'desc'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /legacy/issues/search/:owner/:repository/:state/:keyword)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
                    _githubcl_compreply "open"$'\n'"closed"
              ;;
              4)
                  __comp_current_options || return
              ;;
              5)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /legacy/repos/search/:keyword)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-language' 'Filter results by language' '--q-start_page' 'The page number to fetch' '--q-sort' 'The sort field. One of stars, forks, or updated. Default: results are sorted by best match.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-language)
                  ;;
                  --q-start_page)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'updated'"$'\n'"'stars'"$'\n'"'forks'"
                  ;;

                esac
                ;;
            esac
          ;;
          /legacy/user/email/:email)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /legacy/user/search/:keyword)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-start_page' 'The page number to fetch' '--q-sort' 'The sort field. One of stars, forks, or updated. Default: results are sorted by best match.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-start_page)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'updated'"$'\n'"'stars'"$'\n'"'forks'"
                  ;;

                esac
                ;;
            esac
          ;;
          /meta)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /networks/:owner/:repo/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications)
            FLAGS+=()
            OPTIONS+=('--q-all' 'True to show notifications marked as read.' '--q-participating' 'True to show only notifications in which the user is directly participating
or mentioned.
' '--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-all)
                  ;;
                  --q-participating)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications/threads/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications/threads/:id/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/issues)
            FLAGS+=()
            OPTIONS+=('--q-filter' 'Issues assigned to you / created by you / mentioning you / you'"'"'re
subscribed to updates for / All issues the authenticated user can see
' '--q-state' '' '--q-labels' 'String list of comma separated Label names. Example - bug,ui,@high.' '--q-sort' '' '--q-direction' '' '--q-since' 'Optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Only issues updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-filter)
                    _githubcl_compreply "'assigned'"$'\n'"'created'"$'\n'"'mentioned'"$'\n'"'subscribed'"$'\n'"'all'"
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-labels)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"$'\n'"'comments'"
                  ;;
                  --q-direction)
                    _githubcl_compreply "'asc'"$'\n'"'desc'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/members)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/public_members)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/public_members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/repos)
            FLAGS+=()
            OPTIONS+=('--q-type' '')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-type)
                    _githubcl_compreply "'all'"$'\n'"'public'"$'\n'"'private'"$'\n'"'forks'"$'\n'"'sources'"$'\n'"'member'"
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/teams)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /rate_limit)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /repos/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/:archive_format/:path)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
                    _githubcl_compreply "tarball"$'\n'"zipball"
              ;;
              5)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/assignees)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/assignees/:assignee)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/branches)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/branches/:branch)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/collaborators)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/collaborators/:user)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/commits)
            FLAGS+=()
            OPTIONS+=('--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
' '--q-sha' 'Sha or branch to start listing commits from.' '--q-path' 'Only commits containing this file path will be returned.' '--q-author' 'GitHub login, name, or email by which to filter by commit author.' '--q-until' 'ISO 8601 Date - Only commits before this date will be returned.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;
                  --q-sha)
                  ;;
                  --q-path)
                  ;;
                  --q-author)
                  ;;
                  --q-until)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/commits/:ref/status)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/commits/:shaCode)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/commits/:shaCode/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/compare/:baseId...:headId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              5)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/contents/:path)
            FLAGS+=()
            OPTIONS+=('--q-path' 'The content path.' '--q-ref' 'The String name of the Commit/Branch/Tag. Defaults to '"'"'master'"'"'.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-path)
                  ;;
                  --q-ref)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/contributors)
            FLAGS+=()
            OPTIONS+=('--q-anon' 'Set to 1 or true to include anonymous contributors in results.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-anon)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/deployments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/deployments/:id/statuses)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/downloads)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/downloads/:downloadId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/forks)
            FLAGS+=()
            OPTIONS+=('--q-sort' '')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'newes'"$'\n'"'oldes'"$'\n'"'watchers'"
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/blobs/:shaCode)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/commits/:shaCode)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/refs)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/refs/:ref)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/tags/:shaCode)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/trees/:shaCode)
            FLAGS+=()
            OPTIONS+=('--q-recursive' 'Get a Tree Recursively. (0 or 1)')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-recursive)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks/:hookId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues)
            FLAGS+=()
            OPTIONS+=('--q-filter' 'Issues assigned to you / created by you / mentioning you / you'"'"'re
subscribed to updates for / All issues the authenticated user can see
' '--q-state' '' '--q-labels' 'String list of comma separated Label names. Example - bug,ui,@high.' '--q-sort' '' '--q-direction' '' '--q-since' 'Optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Only issues updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-filter)
                    _githubcl_compreply "'assigned'"$'\n'"'created'"$'\n'"'mentioned'"$'\n'"'subscribed'"$'\n'"'all'"
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-labels)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"$'\n'"'comments'"
                  ;;
                  --q-direction)
                    _githubcl_compreply "'asc'"$'\n'"'desc'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/comments)
            FLAGS+=()
            OPTIONS+=('--q-direction' 'Ignored without '"'"'sort'"'"' parameter.' '--q-sort' '' '--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-direction)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/events/:eventId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/keys)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/keys/:keyId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/labels/:name)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/languages)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones)
            FLAGS+=()
            OPTIONS+=('--q-state' 'String to filter by state.' '--q-direction' 'Ignored without '"'"'sort'"'"' parameter.' '--q-sort' '')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-direction)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'due_date'"$'\n'"'completeness'"
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones/:number/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/notifications)
            FLAGS+=()
            OPTIONS+=('--q-all' 'True to show notifications marked as read.' '--q-participating' 'True to show only notifications in which the user is directly participating
or mentioned.
' '--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-all)
                  ;;
                  --q-participating)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls)
            FLAGS+=()
            OPTIONS+=('--q-state' 'String to filter by state.' '--q-head' 'Filter pulls by head user and branch name in the format of '"'"'user:ref-name'"'"'.
Example: github:new-script-format.
' '--q-base' 'Filter pulls by base branch name. Example - gh-pages.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-head)
                  ;;
                  --q-base)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/commits)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/files)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/merge)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/comments)
            FLAGS+=()
            OPTIONS+=('--q-direction' 'Ignored without '"'"'sort'"'"' parameter.' '--q-sort' '' '--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-direction)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/readme)
            FLAGS+=()
            OPTIONS+=('--q-ref' 'The String name of the Commit/Branch/Tag. Defaults to master.')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-ref)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/:id/assets)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/assets/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stargazers)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stats/code_frequency)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stats/commit_activity)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stats/contributors)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stats/participation)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/stats/punch_card)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/statuses/:ref)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/subscribers)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/tags)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/teams)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/watchers)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repositories)
            FLAGS+=()
            OPTIONS+=('--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /search/code)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-q' 'The search terms. This can be any combination of the supported code
search parameters:
'"'"'Search In'"'"' Qualifies which fields are searched. With this qualifier
you can restrict the search to just the file contents, the file path,
or both.
'"'"'Languages'"'"' Searches code based on the language it'"'"'s written in.
'"'"'Forks'"'"' Filters repositories based on the number of forks, and/or
whether code from forked repositories should be included in the results
at all.
'"'"'Size'"'"' Finds files that match a certain size (in bytes).
'"'"'Path'"'"' Specifies the path that the resulting file must be at.
'"'"'Extension'"'"' Matches files with a certain extension.
'"'"'Users'"'"' or '"'"'Repositories'"'"' Limits searches to a specific user or repository.
' '--q-sort' 'Can only be '"'"'indexed'"'"', which indicates how recently a file has been indexed
by the GitHub search infrastructure. If not provided, results are sorted
by best match.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-q)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'indexed'"
                  ;;

                esac
                ;;
            esac
          ;;
          /search/issues)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-q' 'The q search term can also contain any combination of the supported issue search qualifiers:' '--q-sort' 'The sort field. Can be comments, created, or updated. Default: results are sorted by best match.')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-q)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'updated'"$'\n'"'created'"$'\n'"'comments'"
                  ;;

                esac
                ;;
            esac
          ;;
          /search/repositories)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-q' 'The search terms. This can be any combination of the supported repository
search parameters:
'"'"'Search In'"'"' Qualifies which fields are searched. With this qualifier you
can restrict the search to just the repository name, description, readme,
or any combination of these.
'"'"'Size'"'"' Finds repositories that match a certain size (in kilobytes).
'"'"'Forks'"'"' Filters repositories based on the number of forks, and/or whether
forked repositories should be included in the results at all.
'"'"'Created'"'"' and '"'"'Last Updated'"'"' Filters repositories based on times of
creation, or when they were last updated.
'"'"'Users or Repositories'"'"' Limits searches to a specific user or repository.
'"'"'Languages'"'"' Searches repositories based on the language they are written in.
'"'"'Stars'"'"' Searches repositories based on the number of stars.
' '--q-sort' 'If not provided, results are sorted by best match.')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-q)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'stars'"$'\n'"'forks'"$'\n'"'updated'"
                  ;;

                esac
                ;;
            esac
          ;;
          /search/users)
            FLAGS+=()
            OPTIONS+=('--q-order' 'The sort field. if sort param is provided. Can be either asc or desc.' '--q-q' 'The search terms. This can be any combination of the supported user
search parameters:
'"'"'Search In'"'"' Qualifies which fields are searched. With this qualifier you
can restrict the search to just the username, public email, full name,
location, or any combination of these.
'"'"'Repository count'"'"' Filters users based on the number of repositories they
have.
'"'"'Location'"'"' Filter users by the location indicated in their profile.
'"'"'Language'"'"' Search for users that have repositories that match a certain
language.
'"'"'Created'"'"' Filter users based on when they joined.
'"'"'Followers'"'"' Filter users based on the number of followers they have.
' '--q-sort' 'If not provided, results are sorted by best match.')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-order)
                    _githubcl_compreply "'desc'"$'\n'"'asc'"
                  ;;
                  --q-q)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'followers'"$'\n'"'repositories'"$'\n'"'joined'"
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/members)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/memberships/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/repos)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/repos/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/emails)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/followers)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/following)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/following/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/issues)
            FLAGS+=()
            OPTIONS+=('--q-filter' 'Issues assigned to you / created by you / mentioning you / you'"'"'re
subscribed to updates for / All issues the authenticated user can see
' '--q-state' '' '--q-labels' 'String list of comma separated Label names. Example - bug,ui,@high.' '--q-sort' '' '--q-direction' '' '--q-since' 'Optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Only issues updated at or after this time are returned.
')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-filter)
                    _githubcl_compreply "'assigned'"$'\n'"'created'"$'\n'"'mentioned'"$'\n'"'subscribed'"$'\n'"'all'"
                  ;;
                  --q-state)
                    _githubcl_compreply "'open'"$'\n'"'closed'"
                  ;;
                  --q-labels)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"$'\n'"'comments'"
                  ;;
                  --q-direction)
                    _githubcl_compreply "'asc'"$'\n'"'desc'"
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/keys)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/keys/:keyId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/orgs)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/repos)
            FLAGS+=()
            OPTIONS+=('--q-type' '')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-type)
                    _githubcl_compreply "'all'"$'\n'"'public'"$'\n'"'private'"$'\n'"'forks'"$'\n'"'sources'"$'\n'"'member'"
                  ;;

                esac
                ;;
            esac
          ;;
          /user/starred)
            FLAGS+=()
            OPTIONS+=('--q-direction' 'Ignored without '"'"'sort'"'"' parameter.' '--q-sort' '')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-direction)
                  ;;
                  --q-sort)
                    _githubcl_compreply "'created'"$'\n'"'updated'"
                  ;;

                esac
                ;;
            esac
          ;;
          /user/starred/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/subscriptions)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/subscriptions/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/teams)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /users)
            FLAGS+=()
            OPTIONS+=('--q-since' 'The integer ID of the last User that you'"'"'ve seen.')
            __githubcl_handle_options_flags
              case $INDEX in
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/events/orgs/:org)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/followers)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/following/:targetUser)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/gists)
            FLAGS+=()
            OPTIONS+=('--q-since' 'The time should be passed in as UTC in the ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.
Example: "2012-10-09T23:39:01Z".
')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-since)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/keys)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/orgs)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/received_events)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/received_events/public)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/repos)
            FLAGS+=()
            OPTIONS+=('--q-type' '')
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;
                  --q-type)
                    _githubcl_compreply "'all'"$'\n'"'public'"$'\n'"'private'"$'\n'"'forks'"$'\n'"'sources'"$'\n'"'member'"
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/starred)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /users/:username/subscriptions)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      PATCH)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' '/gists/:id'$'\t''Edit a gist.'$'\n''/gists/:id/comments/:commentId'$'\t''Edit a comment.'$'\n''/notifications/threads/:id'$'\t''Mark a thread as read'$'\n''/orgs/:org'$'\t''Edit an Organization.'$'\n''/repos/:owner/:repo'$'\t''Edit repository.'$'\n''/repos/:owner/:repo/comments/:commentId'$'\t''Update a commit comment.'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\t''Update a Reference'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\t''Edit a hook.'$'\n''/repos/:owner/:repo/issues/:number'$'\t''Edit an issue.'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\t''Edit a comment.'$'\n''/repos/:owner/:repo/labels/:name'$'\t''Update a label.'$'\n''/repos/:owner/:repo/milestones/:number'$'\t''Update a milestone.'$'\n''/repos/:owner/:repo/pulls/:number'$'\t''Update a pull request.'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\t''Edit a comment.'$'\n''/repos/:owner/:repo/releases/:id'$'\t''Users with push access to the repository can edit ...'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\t''Edit a release asset'$'\n''/teams/:teamId'$'\t''Edit team.'$'\n''/user'$'\t''Update the authenticated user.'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          /gists/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications/threads/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/refs/:ref)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks/:hookId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/labels/:name)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/comments/:commentId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases/assets/:id)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
        esac

        ;;
        esac
      ;;
      POST)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' '/gists'$'\t''Create a gist.'$'\n''/gists/:id/comments'$'\t''Create a commen'$'\n''/gists/:id/forks'$'\t''Fork a gist.'$'\n''/markdown'$'\t''Render an arbitrary Markdown document...'$'\n''/markdown/raw'$'\t''Render a Markdown document in raw mode...'$'\n''/orgs/:org/repos'$'\t''Create a new repository for the authenticated user...'$'\n''/orgs/:org/teams'$'\t''Create team.'$'\n''/repos/:owner/:repo/commits/:shaCode/comments'$'\t''Create a commit comment.'$'\n''/repos/:owner/:repo/deployments'$'\t''Users with push access can create a deployment for...'$'\n''/repos/:owner/:repo/deployments/:id/statuses'$'\t''Create a Deployment Status'$'\n''/repos/:owner/:repo/forks'$'\t''Create a fork.'$'\n''/repos/:owner/:repo/git/blobs'$'\t''Create a Blob.'$'\n''/repos/:owner/:repo/git/commits'$'\t''Create a Commit.'$'\n''/repos/:owner/:repo/git/refs'$'\t''Create a Reference'$'\n''/repos/:owner/:repo/git/tags'$'\t''Create a Tag Object.'$'\n''/repos/:owner/:repo/git/trees'$'\t''Create a Tree.'$'\n''/repos/:owner/:repo/hooks'$'\t''Create a hook.'$'\n''/repos/:owner/:repo/hooks/:hookId/tests'$'\t''Test a push hook.'$'\n''/repos/:owner/:repo/issues'$'\t''Create an issue.'$'\n''/repos/:owner/:repo/issues/:number/comments'$'\t''Create a comment.'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\t''Add labels to an issue.'$'\n''/repos/:owner/:repo/keys'$'\t''Create a key.'$'\n''/repos/:owner/:repo/labels'$'\t''Create a label.'$'\n''/repos/:owner/:repo/merges'$'\t''Perform a merge.'$'\n''/repos/:owner/:repo/milestones'$'\t''Create a milestone.'$'\n''/repos/:owner/:repo/pulls'$'\t''Create a pull request.'$'\n''/repos/:owner/:repo/pulls/:number/comments'$'\t''Create a comment.'$'\n''/repos/:owner/:repo/releases'$'\t''Create a release'$'\n''/repos/:owner/:repo/statuses/:ref'$'\t''Create a Status.'$'\n''/user/emails'$'\t''Add email address(es).'$'\n''/user/keys'$'\t''Create a public key.'$'\n''/user/repos'$'\t''Create a new repository for the authenticated user...'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          /gists)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /gists/:id/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /gists/:id/forks)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /markdown)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /markdown/raw)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /orgs/:org/repos)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/teams)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/commits/:shaCode/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/deployments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/deployments/:id/statuses)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/forks)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/blobs)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/commits)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/refs)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/tags)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/git/trees)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/hooks/:hookId/tests)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/keys)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/merges)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/milestones)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/comments)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/releases)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/statuses/:ref)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/emails)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/keys)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /user/repos)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
        esac

        ;;
        esac
      ;;
      PUT)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' '/gists/:id/star'$'\t''Star a gist.'$'\n''/notifications'$'\t''Mark as read.'$'\n''/notifications/threads/:id/subscription'$'\t''Set a Thread Subscription.'$'\n''/orgs/:org/public_members/:username'$'\t''Publicize a user'"'"'s membership.'$'\n''/repos/:owner/:repo/collaborators/:user'$'\t''Add collaborator.'$'\n''/repos/:owner/:repo/contents/:path'$'\t''Create a file.'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\t''Replace all labels for an issue....'$'\n''/repos/:owner/:repo/notifications'$'\t''Mark notifications as read in a repository....'$'\n''/repos/:owner/:repo/pulls/:number/merge'$'\t''Merge a pull request (Merge Button'"'"'s)...'$'\n''/repos/:owner/:repo/subscription'$'\t''Set a Repository Subscription'$'\n''/teams/:teamId/members/:username'$'\t''The API (described below) is deprecated and is sch...'$'\n''/teams/:teamId/memberships/:username'$'\t''Add team membership.'$'\n''/teams/:teamId/repos/:org/:repo'$'\t''In order to add a repository to a team, the authen...'$'\n''/user/following/:username'$'\t''Follow a user.'$'\n''/user/starred/:owner/:repo'$'\t''Star a repository.'$'\n''/user/subscriptions/:owner/:repo'$'\t''Watch a repository.'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          /gists/:id/star)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /notifications)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            __comp_current_options true || return # no subcmds, no params/opts
          ;;
          /notifications/threads/:id/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /orgs/:org/public_members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/collaborators/:user)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/contents/:path)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/issues/:number/labels)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/notifications)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/pulls/:number/merge)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /repos/:owner/:repo/subscription)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/members/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/memberships/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /teams/:teamId/repos/:org/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              4)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/following/:username)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/starred/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
          /user/subscriptions/:owner/:repo)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
              case $INDEX in
              2)
                  __comp_current_options || return
              ;;
              3)
                  __comp_current_options || return
              ;;
              *)
                __comp_current_options true || return # after parameters
                case ${MYWORDS[$INDEX-1]} in
                  --data-file)
                  ;;

                esac
                ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      _meta)
        FLAGS+=()
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' 'completion'$'\t''Shell completion functions'$'\n''pod'$'\t''Pod documentation'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          completion)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' 'generate'$'\t''Generate self completion'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              generate)
                FLAGS+=('--zsh' 'for zsh' '--bash' 'for bash')
                OPTIONS+=('--name' 'name of the program (optional, override name in spec)')
                __githubcl_handle_options_flags
                  case $INDEX in
                  *)
                    __comp_current_options true || return # after parameters
                    case ${MYWORDS[$INDEX-1]} in
                      --data-file)
                      ;;
                      --name)
                      ;;

                    esac
                    ;;
                esac
              ;;
            esac

            ;;
            esac
          ;;
          pod)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' 'generate'$'\t''Generate self pod'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              generate)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
      help)
        FLAGS+=('--all' '')
        OPTIONS+=()
        __githubcl_handle_options_flags
        case $INDEX in

        1)
            __comp_current_options || return
            __githubcl_dynamic_comp 'commands' 'DELETE'$'\n''GET'$'\n''PATCH'$'\n''POST'$'\n''PUT'

        ;;
        *)
        # subcmds
        case ${MYWORDS[1]} in
          DELETE)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' '/gists/:id'$'\n''/gists/:id/comments/:commentId'$'\n''/gists/:id/star'$'\n''/notifications/threads/:id/subscription'$'\n''/orgs/:org/members/:username'$'\n''/orgs/:org/public_members/:username'$'\n''/repos/:owner/:repo'$'\n''/repos/:owner/:repo/collaborators/:user'$'\n''/repos/:owner/:repo/comments/:commentId'$'\n''/repos/:owner/:repo/contents/:path'$'\n''/repos/:owner/:repo/downloads/:downloadId'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\n''/repos/:owner/:repo/issues/:number/labels/:name'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\n''/repos/:owner/:repo/keys/:keyId'$'\n''/repos/:owner/:repo/labels/:name'$'\n''/repos/:owner/:repo/milestones/:number'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\n''/repos/:owner/:repo/releases/:id'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\n''/repos/:owner/:repo/subscription'$'\n''/teams/:teamId'$'\n''/teams/:teamId/members/:username'$'\n''/teams/:teamId/memberships/:username'$'\n''/teams/:teamId/repos/:owner/:repo'$'\n''/user/emails'$'\n''/user/following/:username'$'\n''/user/keys/:keyId'$'\n''/user/starred/:owner/:repo'$'\n''/user/subscriptions/:owner/:repo'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              /gists/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/star)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications/threads/:id/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/public_members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/collaborators/:user)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/contents/:path)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/downloads/:downloadId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/refs/:ref)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks/:hookId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/labels/:name)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/keys/:keyId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/labels/:name)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/assets/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/memberships/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/repos/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/emails)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/following/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/keys/:keyId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/starred/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/subscriptions/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
          GET)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' '/emojis'$'\n''/events'$'\n''/feeds'$'\n''/gists'$'\n''/gists/:id'$'\n''/gists/:id/comments'$'\n''/gists/:id/comments/:commentId'$'\n''/gists/:id/star'$'\n''/gists/public'$'\n''/gists/starred'$'\n''/gitignore/templates'$'\n''/gitignore/templates/:language'$'\n''/issues'$'\n''/legacy/issues/search/:owner/:repository/:state/:keyword'$'\n''/legacy/repos/search/:keyword'$'\n''/legacy/user/email/:email'$'\n''/legacy/user/search/:keyword'$'\n''/meta'$'\n''/networks/:owner/:repo/events'$'\n''/notifications'$'\n''/notifications/threads/:id'$'\n''/notifications/threads/:id/subscription'$'\n''/orgs/:org'$'\n''/orgs/:org/events'$'\n''/orgs/:org/issues'$'\n''/orgs/:org/members'$'\n''/orgs/:org/members/:username'$'\n''/orgs/:org/public_members'$'\n''/orgs/:org/public_members/:username'$'\n''/orgs/:org/repos'$'\n''/orgs/:org/teams'$'\n''/rate_limit'$'\n''/repos/:owner/:repo'$'\n''/repos/:owner/:repo/:archive_format/:path'$'\n''/repos/:owner/:repo/assignees'$'\n''/repos/:owner/:repo/assignees/:assignee'$'\n''/repos/:owner/:repo/branches'$'\n''/repos/:owner/:repo/branches/:branch'$'\n''/repos/:owner/:repo/collaborators'$'\n''/repos/:owner/:repo/collaborators/:user'$'\n''/repos/:owner/:repo/comments'$'\n''/repos/:owner/:repo/comments/:commentId'$'\n''/repos/:owner/:repo/commits'$'\n''/repos/:owner/:repo/commits/:ref/status'$'\n''/repos/:owner/:repo/commits/:shaCode'$'\n''/repos/:owner/:repo/commits/:shaCode/comments'$'\n''/repos/:owner/:repo/compare/:baseId...:headId'$'\n''/repos/:owner/:repo/contents/:path'$'\n''/repos/:owner/:repo/contributors'$'\n''/repos/:owner/:repo/deployments'$'\n''/repos/:owner/:repo/deployments/:id/statuses'$'\n''/repos/:owner/:repo/downloads'$'\n''/repos/:owner/:repo/downloads/:downloadId'$'\n''/repos/:owner/:repo/events'$'\n''/repos/:owner/:repo/forks'$'\n''/repos/:owner/:repo/git/blobs/:shaCode'$'\n''/repos/:owner/:repo/git/commits/:shaCode'$'\n''/repos/:owner/:repo/git/refs'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\n''/repos/:owner/:repo/git/tags/:shaCode'$'\n''/repos/:owner/:repo/git/trees/:shaCode'$'\n''/repos/:owner/:repo/hooks'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\n''/repos/:owner/:repo/issues'$'\n''/repos/:owner/:repo/issues/:number'$'\n''/repos/:owner/:repo/issues/:number/comments'$'\n''/repos/:owner/:repo/issues/:number/events'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\n''/repos/:owner/:repo/issues/comments'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\n''/repos/:owner/:repo/issues/events'$'\n''/repos/:owner/:repo/issues/events/:eventId'$'\n''/repos/:owner/:repo/keys'$'\n''/repos/:owner/:repo/keys/:keyId'$'\n''/repos/:owner/:repo/labels'$'\n''/repos/:owner/:repo/labels/:name'$'\n''/repos/:owner/:repo/languages'$'\n''/repos/:owner/:repo/milestones'$'\n''/repos/:owner/:repo/milestones/:number'$'\n''/repos/:owner/:repo/milestones/:number/labels'$'\n''/repos/:owner/:repo/notifications'$'\n''/repos/:owner/:repo/pulls'$'\n''/repos/:owner/:repo/pulls/:number'$'\n''/repos/:owner/:repo/pulls/:number/comments'$'\n''/repos/:owner/:repo/pulls/:number/commits'$'\n''/repos/:owner/:repo/pulls/:number/files'$'\n''/repos/:owner/:repo/pulls/:number/merge'$'\n''/repos/:owner/:repo/pulls/comments'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\n''/repos/:owner/:repo/readme'$'\n''/repos/:owner/:repo/releases'$'\n''/repos/:owner/:repo/releases/:id'$'\n''/repos/:owner/:repo/releases/:id/assets'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\n''/repos/:owner/:repo/stargazers'$'\n''/repos/:owner/:repo/stats/code_frequency'$'\n''/repos/:owner/:repo/stats/commit_activity'$'\n''/repos/:owner/:repo/stats/contributors'$'\n''/repos/:owner/:repo/stats/participation'$'\n''/repos/:owner/:repo/stats/punch_card'$'\n''/repos/:owner/:repo/statuses/:ref'$'\n''/repos/:owner/:repo/subscribers'$'\n''/repos/:owner/:repo/subscription'$'\n''/repos/:owner/:repo/tags'$'\n''/repos/:owner/:repo/teams'$'\n''/repos/:owner/:repo/watchers'$'\n''/repositories'$'\n''/search/code'$'\n''/search/issues'$'\n''/search/repositories'$'\n''/search/users'$'\n''/teams/:teamId'$'\n''/teams/:teamId/members'$'\n''/teams/:teamId/members/:username'$'\n''/teams/:teamId/memberships/:username'$'\n''/teams/:teamId/repos'$'\n''/teams/:teamId/repos/:owner/:repo'$'\n''/user'$'\n''/user/emails'$'\n''/user/followers'$'\n''/user/following'$'\n''/user/following/:username'$'\n''/user/issues'$'\n''/user/keys'$'\n''/user/keys/:keyId'$'\n''/user/orgs'$'\n''/user/repos'$'\n''/user/starred'$'\n''/user/starred/:owner/:repo'$'\n''/user/subscriptions'$'\n''/user/subscriptions/:owner/:repo'$'\n''/user/teams'$'\n''/users'$'\n''/users/:username'$'\n''/users/:username/events'$'\n''/users/:username/events/orgs/:org'$'\n''/users/:username/followers'$'\n''/users/:username/following/:targetUser'$'\n''/users/:username/gists'$'\n''/users/:username/keys'$'\n''/users/:username/orgs'$'\n''/users/:username/received_events'$'\n''/users/:username/received_events/public'$'\n''/users/:username/repos'$'\n''/users/:username/starred'$'\n''/users/:username/subscriptions'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              /emojis)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /feeds)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/star)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/public)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/starred)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gitignore/templates)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gitignore/templates/:language)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /legacy/issues/search/:owner/:repository/:state/:keyword)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /legacy/repos/search/:keyword)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /legacy/user/email/:email)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /legacy/user/search/:keyword)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /meta)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /networks/:owner/:repo/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications/threads/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications/threads/:id/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/members)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/public_members)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/public_members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/teams)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /rate_limit)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/:archive_format/:path)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/assignees)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/assignees/:assignee)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/branches)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/branches/:branch)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/collaborators)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/collaborators/:user)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/commits)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/commits/:ref/status)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/commits/:shaCode)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/commits/:shaCode/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/compare/:baseId...:headId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/contents/:path)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/contributors)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/deployments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/deployments/:id/statuses)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/downloads)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/downloads/:downloadId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/forks)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/blobs/:shaCode)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/commits/:shaCode)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/refs)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/refs/:ref)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/tags/:shaCode)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/trees/:shaCode)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks/:hookId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/events/:eventId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/keys)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/keys/:keyId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/labels/:name)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/languages)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones/:number/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/notifications)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/commits)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/files)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/merge)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/readme)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/:id/assets)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/assets/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stargazers)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stats/code_frequency)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stats/commit_activity)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stats/contributors)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stats/participation)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/stats/punch_card)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/statuses/:ref)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/subscribers)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/tags)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/teams)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/watchers)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repositories)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /search/code)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /search/issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /search/repositories)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /search/users)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/members)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/memberships/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/repos/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/emails)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/followers)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/following)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/following/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/keys)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/keys/:keyId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/orgs)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/starred)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/starred/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/subscriptions)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/subscriptions/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/teams)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/events/orgs/:org)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/followers)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/following/:targetUser)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/gists)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/keys)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/orgs)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/received_events)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/received_events/public)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/starred)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /users/:username/subscriptions)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
          PATCH)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' '/gists/:id'$'\n''/gists/:id/comments/:commentId'$'\n''/notifications/threads/:id'$'\n''/orgs/:org'$'\n''/repos/:owner/:repo'$'\n''/repos/:owner/:repo/comments/:commentId'$'\n''/repos/:owner/:repo/git/refs/:ref'$'\n''/repos/:owner/:repo/hooks/:hookId'$'\n''/repos/:owner/:repo/issues/:number'$'\n''/repos/:owner/:repo/issues/comments/:commentId'$'\n''/repos/:owner/:repo/labels/:name'$'\n''/repos/:owner/:repo/milestones/:number'$'\n''/repos/:owner/:repo/pulls/:number'$'\n''/repos/:owner/:repo/pulls/comments/:commentId'$'\n''/repos/:owner/:repo/releases/:id'$'\n''/repos/:owner/:repo/releases/assets/:id'$'\n''/teams/:teamId'$'\n''/user'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              /gists/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications/threads/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/refs/:ref)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks/:hookId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/labels/:name)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/comments/:commentId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases/assets/:id)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
          POST)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' '/gists'$'\n''/gists/:id/comments'$'\n''/gists/:id/forks'$'\n''/markdown'$'\n''/markdown/raw'$'\n''/orgs/:org/repos'$'\n''/orgs/:org/teams'$'\n''/repos/:owner/:repo/commits/:shaCode/comments'$'\n''/repos/:owner/:repo/deployments'$'\n''/repos/:owner/:repo/deployments/:id/statuses'$'\n''/repos/:owner/:repo/forks'$'\n''/repos/:owner/:repo/git/blobs'$'\n''/repos/:owner/:repo/git/commits'$'\n''/repos/:owner/:repo/git/refs'$'\n''/repos/:owner/:repo/git/tags'$'\n''/repos/:owner/:repo/git/trees'$'\n''/repos/:owner/:repo/hooks'$'\n''/repos/:owner/:repo/hooks/:hookId/tests'$'\n''/repos/:owner/:repo/issues'$'\n''/repos/:owner/:repo/issues/:number/comments'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\n''/repos/:owner/:repo/keys'$'\n''/repos/:owner/:repo/labels'$'\n''/repos/:owner/:repo/merges'$'\n''/repos/:owner/:repo/milestones'$'\n''/repos/:owner/:repo/pulls'$'\n''/repos/:owner/:repo/pulls/:number/comments'$'\n''/repos/:owner/:repo/releases'$'\n''/repos/:owner/:repo/statuses/:ref'$'\n''/user/emails'$'\n''/user/keys'$'\n''/user/repos'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              /gists)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /gists/:id/forks)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /markdown)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /markdown/raw)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/teams)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/commits/:shaCode/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/deployments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/deployments/:id/statuses)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/forks)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/blobs)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/commits)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/refs)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/tags)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/git/trees)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/hooks/:hookId/tests)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/keys)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/merges)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/milestones)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/comments)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/releases)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/statuses/:ref)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/emails)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/keys)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/repos)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
          PUT)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' '/gists/:id/star'$'\n''/notifications'$'\n''/notifications/threads/:id/subscription'$'\n''/orgs/:org/public_members/:username'$'\n''/repos/:owner/:repo/collaborators/:user'$'\n''/repos/:owner/:repo/contents/:path'$'\n''/repos/:owner/:repo/issues/:number/labels'$'\n''/repos/:owner/:repo/notifications'$'\n''/repos/:owner/:repo/pulls/:number/merge'$'\n''/repos/:owner/:repo/subscription'$'\n''/teams/:teamId/members/:username'$'\n''/teams/:teamId/memberships/:username'$'\n''/teams/:teamId/repos/:org/:repo'$'\n''/user/following/:username'$'\n''/user/starred/:owner/:repo'$'\n''/user/subscriptions/:owner/:repo'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              /gists/:id/star)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /notifications/threads/:id/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /orgs/:org/public_members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/collaborators/:user)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/contents/:path)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/issues/:number/labels)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/notifications)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/pulls/:number/merge)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /repos/:owner/:repo/subscription)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/members/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/memberships/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /teams/:teamId/repos/:org/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/following/:username)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/starred/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
              /user/subscriptions/:owner/:repo)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                __comp_current_options true || return # no subcmds, no params/opts
              ;;
            esac

            ;;
            esac
          ;;
          _meta)
            FLAGS+=()
            OPTIONS+=()
            __githubcl_handle_options_flags
            case $INDEX in

            2)
                __comp_current_options || return
                __githubcl_dynamic_comp 'commands' 'completion'$'\n''pod'

            ;;
            *)
            # subcmds
            case ${MYWORDS[2]} in
              completion)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                case $INDEX in

                3)
                    __comp_current_options || return
                    __githubcl_dynamic_comp 'commands' 'generate'

                ;;
                *)
                # subcmds
                case ${MYWORDS[3]} in
                  generate)
                    FLAGS+=()
                    OPTIONS+=()
                    __githubcl_handle_options_flags
                    __comp_current_options true || return # no subcmds, no params/opts
                  ;;
                esac

                ;;
                esac
              ;;
              pod)
                FLAGS+=()
                OPTIONS+=()
                __githubcl_handle_options_flags
                case $INDEX in

                3)
                    __comp_current_options || return
                    __githubcl_dynamic_comp 'commands' 'generate'

                ;;
                *)
                # subcmds
                case ${MYWORDS[3]} in
                  generate)
                    FLAGS+=()
                    OPTIONS+=()
                    __githubcl_handle_options_flags
                    __comp_current_options true || return # no subcmds, no params/opts
                  ;;
                esac

                ;;
                esac
              ;;
            esac

            ;;
            esac
          ;;
        esac

        ;;
        esac
      ;;
    esac

    ;;
    esac

}

_githubcl_compreply() {
    IFS=$'\n' COMPREPLY=($(compgen -W "$1" -- ${COMP_WORDS[COMP_CWORD]}))
    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then # Only one completion
        COMPREPLY=( ${COMPREPLY[0]%% -- *} ) # Remove ' -- ' and everything after
        COMPREPLY="$(echo -e "$COMPREPLY" | sed -e 's/[[:space:]]*$//')"
    fi
}


__githubcl_dynamic_comp() {
    local argname="$1"
    local arg="$2"
    local comp name desc cols desclength formatted
    local max=0

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        if [[ "${#name}" -gt "$max" ]]; then
            max="${#name}"
        fi
    done <<< "$arg"

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        desc="${desc/*$'\t'}"
        if [[ -n "$desc" && "$desc" != "$name" ]]; then
            # TODO portable?
            cols=`tput cols`
            [[ -z $cols ]] && cols=80
            desclength=`expr $cols - 4 - $max`
            formatted=`printf "'%-*s -- %-*s'" "$max" "$name" "$desclength" "$desc"`
            comp="$comp$formatted"$'\n'
        else
            comp="$comp'$name'"$'\n'
        fi
    done <<< "$arg"
    _githubcl_compreply "$comp"
}

function __githubcl_handle_options() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#OPTIONS[@]}; j+=2))
        do
            local option="${OPTIONS[$j]}"
            if [[ "$word" == "$option" ]]; then
                found=1
                i=`expr $i + 1`
                break
            fi
        done
        if [[ -n $found && $i -lt $max ]]; then
            INDEX=`expr $INDEX - 2`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

function __githubcl_handle_flags() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#FLAGS[@]}; j+=2))
        do
            local flag="${FLAGS[$j]}"
            if [[ "$word" == "$flag" ]]; then
                found=1
                break
            fi
        done
        if [[ -n $found ]]; then
            INDEX=`expr $INDEX - 1`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

__githubcl_handle_options_flags() {
    __githubcl_handle_options
    __githubcl_handle_flags
}

__comp_current_options() {
    local always="$1"
    if [[ -n $always || ${MYWORDS[$INDEX]} =~ ^- ]]; then

      local options_spec=''
      local j=

      for ((j=0; j<${#FLAGS[@]}; j+=2))
      do
          local name="${FLAGS[$j]}"
          local desc="${FLAGS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done

      for ((j=0; j<${#OPTIONS[@]}; j+=2))
      do
          local name="${OPTIONS[$j]}"
          local desc="${OPTIONS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done
      __githubcl_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}


complete -o default -F _githubcl githubcl

